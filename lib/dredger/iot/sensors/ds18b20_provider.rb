# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for DS18B20 1-Wire temperature sensor.
      # Uses the Linux kernel w1-gpio module (w1_therm driver).
      #
      # Setup:
      # 1. Enable w1-gpio in device tree or config.txt (Raspberry Pi)
      # 2. Load modules: modprobe w1-gpio && modprobe w1-therm
      # 3. Devices appear in /sys/bus/w1/devices/28-*/w1_slave
      #
      # Device IDs are 64-bit unique addresses, typically formatted as:
      # "28-0000056789ab" (family code 28 = DS18B20)
      class DS18B20Provider
        W1_BASE_PATH = '/sys/bus/w1/devices'

        def initialize(base_path: W1_BASE_PATH)
          @base_path = base_path
        end

        # Read temperature from DS18B20 sensor.
        # device_id: device address (e.g., "28-0000056789ab")
        # Returns temperature in Celsius as Float
        def read_temperature(device_id)
          device_path = File.join(@base_path, device_id, 'w1_slave')
          raise IOError, "DS18B20 device not found: #{device_id}" unless File.exist?(device_path)

          # Read device file (contains CRC check and temperature)
          content = File.read(device_path)
          lines = content.split("\n")

          # First line contains CRC status: "xx xx xx xx xx xx xx xx xx : crc=xx YES"
          raise IOError, 'DS18B20 CRC check failed' unless lines[0]&.end_with?('YES')

          # Second line contains temperature: "xx xx xx xx xx xx xx xx xx t=23437"
          temp_match = lines[1]&.match(/t=(-?\d+)/)
          raise IOError, 'DS18B20 temperature parse failed' unless temp_match

          # Temperature is in millidegrees Celsius
          temp_match[1].to_i / 1000.0
        end

        # List all connected DS18B20 devices
        def list_devices
          return [] unless Dir.exist?(@base_path)

          Dir.glob(File.join(@base_path, '28-*')).map { |path| File.basename(path) }
        end
      end
    end
  end
end
# EOF
