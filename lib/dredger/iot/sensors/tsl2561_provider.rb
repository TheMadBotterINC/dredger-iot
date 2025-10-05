# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for TSL2561 ambient light sensor (I2C)
      # Uses simple configuration: integration 402ms, low gain.
      class TSL2561Provider
        CMD = 0x80
        CONTROL = 0x00
        TIMING = 0x01
        DATA0LOW = 0x0C
        DATA1LOW = 0x0E

        POWER_ON = 0x03
        POWER_OFF = 0x00
        INTEG_402MS = 0x02 # integration time bits [1:0] = 10
        GAIN_LOW = 0x00    # gain bit [4] = 0

        def initialize(i2c_bus:)
          @i2c = i2c_bus
        end

        # Returns lux as Float
        def read_lux(addr)
          # Power on
          @i2c.write(addr, [POWER_ON], register: CMD | CONTROL)
          # Set timing: 402ms, low gain
          @i2c.write(addr, [GAIN_LOW | INTEG_402MS], register: CMD | TIMING)

          # Wait for integration
          sleep(0.45)

          ch0 = read_word(addr, CMD | DATA0LOW)
          ch1 = read_word(addr, CMD | DATA1LOW)

          compute_lux(ch0, ch1).to_f
        ensure
          # Power off to save energy
          @i2c.write(addr, [POWER_OFF], register: CMD | CONTROL)
        end

        private

        # Read 16-bit little-endian word from LSB register
        def read_word(addr, reg)
          bytes = @i2c.read(addr, 2, register: reg)
          bytes[0] | (bytes[1] << 8)
        end

        # Lux calculation based on TSL2561 datasheet/Adafruit library
        def compute_lux(ch0, ch1)
          return 0.0 if ch0.zero?

          ratio = ch1.to_f / ch0.to_f

          if ratio <= 0.5
            (0.0304 * ch0) - (0.062 * ch0 * (ratio**1.4))
          elsif ratio <= 0.61
            (0.0224 * ch0) - (0.031 * ch1)
          elsif ratio <= 0.80
            (0.0128 * ch0) - (0.0153 * ch1)
          elsif ratio <= 1.30
            (0.00146 * ch0) - (0.00112 * ch1)
          else
            0.0
          end
        end
      end
    end
  end
end