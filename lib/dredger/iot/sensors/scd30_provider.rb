# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for SCD30 CO2, temperature, and humidity sensor over I2C.
      # Datasheet: https://sensirion.com/media/documents/4EAF6AF8/61652C3C/Sensirion_CO2_Sensors_SCD30_Datasheet.pdf
      #
      # Key features:
      # - NDIR CO2 sensor (400-10,000 ppm range)
      # - Integrated SHT31 temperature and humidity sensor
      # - I2C interface (default address: 0x61)
      # - Automatic self-calibration
      # - Measurement interval: 2-1800 seconds
      #
      # Key commands:
      # - 0x0010: Start continuous measurement
      # - 0x0104: Stop continuous measurement
      # - 0x0202: Set measurement interval
      # - 0x0300: Data ready status
      # - 0x0027: Read measurement (18 bytes: CO2, temp, humidity)
      class SCD30Provider
        CMD_START_MEASUREMENT = 0x0010
        CMD_STOP_MEASUREMENT = 0x0104
        CMD_SET_INTERVAL = 0x0202
        CMD_DATA_READY = 0x0300
        CMD_READ_MEASUREMENT = 0x0027

        # i2c_bus: an I2C bus interface (e.g., Dredger::IoT::Bus::Auto.i2c)
        # interval: measurement interval in seconds (2-1800)
        # ambient_pressure: ambient pressure compensation in mBar (700-1400, 0=disable)
        def initialize(i2c_bus:, interval: 2, ambient_pressure: 0)
          @i2c = i2c_bus
          @interval = interval
          @ambient_pressure = ambient_pressure
          @initialized = false
        end

        # Read measurements from the SCD30 at the given I2C address.
        # Returns { co2_ppm: Float, temperature_c: Float, humidity: Float }
        def read_measurements(addr)
          # Initialize sensor on first read
          initialize_sensor(addr) unless @initialized

          # Wait for data ready
          wait_for_data_ready(addr)

          # Read 18 bytes of measurement data
          # Format: [CO2_MSB, CO2_LSB, CO2_CRC] [CO2_MSB, CO2_LSB, CO2_CRC] [T_MSB, T_LSB, T_CRC] [T_MSB, T_LSB, T_CRC] [H_MSB, H_LSB, H_CRC] [H_MSB, H_LSB, H_CRC]
          # Actually: 3 float32 values (4 bytes each + CRC after every 2 bytes = 6 bytes per value)
          @i2c.write(addr, [CMD_READ_MEASUREMENT >> 8, CMD_READ_MEASUREMENT & 0xFF])
          sleep(0.01) # Wait for response
          raw = @i2c.read(addr, 18)

          # Parse float32 values with CRC validation
          co2_ppm = parse_float32_with_crc(raw, 0)
          temp_c = parse_float32_with_crc(raw, 6)
          humidity = parse_float32_with_crc(raw, 12)

          {
            co2_ppm: co2_ppm.round(1),
            temperature_c: temp_c.round(2),
            humidity: humidity.round(1)
          }
        end

        private

        # Initialize sensor with measurement interval and start continuous measurement
        def initialize_sensor(addr)
          # Set measurement interval
          write_command_with_arg(addr, CMD_SET_INTERVAL, @interval)
          sleep(0.01)

          # Start continuous measurement with optional pressure compensation
          write_command_with_arg(addr, CMD_START_MEASUREMENT, @ambient_pressure)
          sleep(0.02)

          @initialized = true
        end

        # Wait for data to be ready (poll data ready status)
        def wait_for_data_ready(addr, timeout: 2.0)
          start_time = Time.now
          loop do
            @i2c.write(addr, [CMD_DATA_READY >> 8, CMD_DATA_READY & 0xFF])
            sleep(0.01)
            status = @i2c.read(addr, 3)
            # Data ready when bit 0 of word is 1
            data_ready = (status[1] & 0x01) == 1
            return if data_ready

            raise IOError, 'SCD30 data ready timeout' if Time.now - start_time > timeout

            sleep(0.1)
          end
        end

        # Write a command with a 16-bit argument and CRC
        def write_command_with_arg(addr, command, arg)
          cmd_msb = command >> 8
          cmd_lsb = command & 0xFF
          arg_msb = arg >> 8
          arg_lsb = arg & 0xFF
          crc = calculate_crc8([arg_msb, arg_lsb])
          @i2c.write(addr, [cmd_msb, cmd_lsb, arg_msb, arg_lsb, crc])
        end

        # Parse a float32 value from 6 bytes (4 data + 2 CRC)
        # Format: [MSB0, LSB0, CRC0, MSB1, LSB1, CRC1]
        def parse_float32_with_crc(data, offset)
          # Verify CRCs
          crc0 = calculate_crc8([data[offset], data[offset + 1]])
          crc1 = calculate_crc8([data[offset + 3], data[offset + 4]])
          raise IOError, 'SCD30 CRC error' unless crc0 == data[offset + 2] && crc1 == data[offset + 5]

          # Combine bytes into uint32 and convert to float32
          bytes = [
            data[offset],
            data[offset + 1],
            data[offset + 3],
            data[offset + 4]
          ].pack('C4').unpack1('N')
          [bytes].pack('L>').unpack1('g')
        end

        # Calculate CRC-8 checksum (polynomial: 0x31, init: 0xFF)
        def calculate_crc8(data)
          crc = 0xFF
          data.each do |byte|
            crc ^= byte
            8.times do
              crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x31) : (crc << 1)
              crc &= 0xFF
            end
          end
          crc
        end
      end
    end
  end
end
