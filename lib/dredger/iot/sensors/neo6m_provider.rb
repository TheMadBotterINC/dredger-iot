# frozen_string_literal: true

require 'io/wait'

module Dredger
  module IoT
    module Sensors
      # Hardware provider for NEO-6M GPS module via UART/Serial with NMEA parsing.
      # Datasheet: https://www.u-blox.com/sites/default/files/products/documents/NEO-6_DataSheet_(GPS.G6-HW-09005).pdf
      #
      # Key features:
      # - 50-channel GPS receiver
      # - UART interface (default: 9600 baud, 8N1)
      # - NMEA 0183 protocol output
      # - Update rate: 1-5 Hz (default: 1 Hz)
      # - Cold start: ~27s, Warm start: ~1s
      #
      # NMEA Sentences:
      # - $GPGGA: Global Positioning System Fix Data (position, altitude, satellites)
      # - $GPRMC: Recommended Minimum Navigation Information (position, speed, date/time)
      # - $GPGSA: GPS DOP and Active Satellites
      # - $GPGSV: GPS Satellites in View
      class NEO6MProvider
        # baud_rate: serial baud rate (default: 9600)
        # timeout: read timeout in seconds (default: 5)
        def initialize(baud_rate: 9600, timeout: 5)
          @baud_rate = baud_rate
          @timeout = timeout
        end

        # Read GPS position by parsing NMEA sentences from the serial device.
        # Returns { latitude: Float, longitude: Float, altitude: Float, speed: Float, satellites: Integer, fix_quality: Integer }
        #
        # @param device [String] Serial device path (e.g., '/dev/ttyAMA0', '/dev/ttyUSB0')
        def read_position(device)
          File.open(device, 'r+') do |serial|
            configure_serial(serial)

            # Read NMEA sentences until we have both GGA and RMC (or timeout)
            gga_data = nil
            rmc_data = nil
            start_time = Time.now

            while (gga_data.nil? || rmc_data.nil?) && (Time.now - start_time < @timeout)
              line = read_line(serial, @timeout)
              next unless line

              if line.start_with?('$GPGGA') || line.start_with?('$GNGGA')
                gga_data = parse_gga(line)
              elsif line.start_with?('$GPRMC') || line.start_with?('$GNRMC')
                rmc_data = parse_rmc(line)
              end
            end

            raise IOError, 'GPS timeout: no valid NMEA sentences received' if gga_data.nil? && rmc_data.nil?

            # Merge data from both sentences (GGA has altitude/satellites, RMC has speed)
            {
              latitude: gga_data&.dig(:latitude) || rmc_data&.dig(:latitude) || 0.0,
              longitude: gga_data&.dig(:longitude) || rmc_data&.dig(:longitude) || 0.0,
              altitude: gga_data&.dig(:altitude) || 0.0,
              speed: rmc_data&.dig(:speed) || 0.0,
              satellites: gga_data&.dig(:satellites) || 0,
              fix_quality: gga_data&.dig(:fix_quality) || 0
            }
          end
        end

        private

        # Configure serial port (Linux termios settings)
        def configure_serial(serial)
          # Set raw mode, no echo, baud rate
          # This would typically use `stty` or `termios` gem
          # For simplicity, assuming device is already configured
          # In production, use: system("stty -F #{device} #{@baud_rate} raw -echo")
        end

        # Read a line from serial with timeout
        def read_line(serial, timeout)
          return nil unless serial.wait_readable(timeout)

          serial.gets&.chomp
        end

        # Parse $GPGGA sentence: Global Positioning System Fix Data
        # Format: $GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh
        # Example: $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
        def parse_gga(sentence)
          parts = sentence.split(',')
          return nil if parts.size < 15 || parts[6].to_i.zero? # Check fix quality

          {
            latitude: parse_coordinate(parts[2], parts[3]),
            longitude: parse_coordinate(parts[4], parts[5]),
            fix_quality: parts[6].to_i,
            satellites: parts[7].to_i,
            altitude: parts[9].to_f
          }
        end

        # Parse $GPRMC sentence: Recommended Minimum Navigation Information
        # Format: $GPRMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,x.x,x.x,ddmmyy,x.x,a*hh
        # Example: $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
        def parse_rmc(sentence)
          parts = sentence.split(',')
          return nil if parts.size < 12 || parts[2] != 'A' # Check if data is valid

          {
            latitude: parse_coordinate(parts[3], parts[4]),
            longitude: parse_coordinate(parts[5], parts[6]),
            speed: parts[7].to_f * 1.852 # Convert knots to km/h
          }
        end

        # Parse NMEA coordinate format (ddmm.mmmm) to decimal degrees
        # @param coord_str [String] Coordinate string (e.g., "4807.038")
        # @param direction [String] Direction (N/S for latitude, E/W for longitude)
        def parse_coordinate(coord_str, direction)
          return 0.0 if coord_str.nil? || coord_str.empty?

          # Determine if latitude or longitude based on length
          # Latitude: ddmm.mmmm (2 digit degrees)
          # Longitude: dddmm.mmmm (3 digit degrees)
          degree_digits = coord_str.length >= 5 && coord_str[4] == '.' ? 2 : 3

          degrees = coord_str[0, degree_digits].to_f
          minutes = coord_str[degree_digits..-1].to_f

          decimal_degrees = degrees + (minutes / 60.0)

          # Apply direction (negative for South and West)
          decimal_degrees *= -1 if %w[S W].include?(direction)

          decimal_degrees.round(6)
        end
      end
    end
  end
end
