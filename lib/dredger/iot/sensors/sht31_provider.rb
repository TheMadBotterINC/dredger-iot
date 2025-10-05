# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for Sensirion SHT31 temperature/humidity over I2C.
      # Basic single-shot measurement without CRC checks for simplicity.
      # Datasheet formula:
      #  - Temperature (°C) = -45 + 175 * (ST / 65535)
      #  - Humidity (%RH)  = 100 * (SRH / 65535)
      class SHT31Provider
        # I2C commands
        CMD_SINGLE_SHOT_HIGHREP = [0x24, 0x00].freeze # High repeatability, clock stretching disabled

        def initialize(i2c_bus:)
          @i2c = i2c_bus
        end

        # Returns { temperature_c: Float, humidity: Float }
        def read_measurements(addr)
          # Trigger single-shot measurement
          @i2c.write(addr, CMD_SINGLE_SHOT_HIGHREP)
          # Max measurement duration ~15ms (high repeatability). Add margin.
          sleep(0.02)

          # Read 6 bytes: T_MSB, T_LSB, T_CRC, RH_MSB, RH_LSB, RH_CRC
          data = @i2c.read(addr, 6)

          st = (data[0] << 8) | data[1]
          srh = (data[3] << 8) | data[4]

          temp_c = -45.0 + (175.0 * st / 65_535.0)
          humidity = (100.0 * srh / 65_535.0)
          humidity = [[humidity, 0.0].max, 100.0].min

          { temperature_c: temp_c, humidity: humidity }
        end
      end
    end
  end
end