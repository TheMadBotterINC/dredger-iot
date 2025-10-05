# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for BH1750 ambient light sensor (I2C)
      # Measurement: Continuous High-Resolution Mode (1 lx, typical 120ms)
      class BH1750Provider
        POWER_ON = 0x01
        RESET = 0x07
        CONT_HIRES = 0x10

        def initialize(i2c_bus:)
          @i2c = i2c_bus
        end

        # Returns lux as Float
        def read_lux(addr)
          # Power on and reset
          @i2c.write(addr, [POWER_ON])
          @i2c.write(addr, [RESET])
          # Start continuous high-resolution measurement
          @i2c.write(addr, [CONT_HIRES])
          # Wait for conversion
          sleep(0.18)
          # Read 2 bytes (big-endian)
          bytes = @i2c.read(addr, 2)
          raw = (bytes[0] << 8) | bytes[1]
          (raw / 1.2).to_f
        end
      end
    end
  end
end