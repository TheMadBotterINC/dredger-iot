# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for ADXL345 3-axis accelerometer over I2C.
      # Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/ADXL345.pdf
      #
      # Key features:
      # - ±2g, ±4g, ±8g, ±16g selectable measurement ranges
      # - 10-bit to 13-bit resolution
      # - I2C (up to 400 kHz) or SPI interface
      # - Default I2C address: 0x53 (ALT address: 0x1D if SDO/ALT pulled high)
      #
      # Key registers:
      # - 0x00: DEVID (should be 0xE5)
      # - 0x2D: POWER_CTL (power modes)
      # - 0x31: DATA_FORMAT (range and resolution)
      # - 0x32-0x37: DATAX0, DATAX1, DATAY0, DATAY1, DATAZ0, DATAZ1 (acceleration data)
      class ADXL345Provider
        DEVID_REG = 0x00
        DEVID_EXPECTED = 0xE5
        POWER_CTL_REG = 0x2D
        DATA_FORMAT_REG = 0x31
        DATAX0_REG = 0x32

        # Measurement mode bit (POWER_CTL register)
        MEASURE_BIT = 0x08

        # i2c_bus: an I2C bus interface (e.g., Dredger::IoT::Bus::Auto.i2c)
        # range: measurement range in g (2, 4, 8, or 16)
        def initialize(i2c_bus:, range: 2)
          @i2c = i2c_bus
          @range = range
          @scale_factor = calculate_scale_factor(range)
        end

        # Read acceleration measurements from the ADXL345 at the given I2C address.
        # Returns { x_g: Float, y_g: Float, z_g: Float }
        def read_measurements(addr)
          # Verify device ID
          dev_id = @i2c.read(addr, 1, register: DEVID_REG).first
          raise IOError, "ADXL345 not found (devid=0x#{dev_id.to_s(16)})" unless dev_id == DEVID_EXPECTED

          # Configure sensor (one-time setup)
          configure_sensor(addr)

          # Read 6 bytes of acceleration data (X, Y, Z as 16-bit signed integers)
          raw = @i2c.read(addr, 6, register: DATAX0_REG)

          # Parse 16-bit signed values (little-endian)
          x_raw = to_signed16(raw[0] | (raw[1] << 8))
          y_raw = to_signed16(raw[2] | (raw[3] << 8))
          z_raw = to_signed16(raw[4] | (raw[5] << 8))

          # Convert to g units using scale factor
          {
            x_g: (x_raw * @scale_factor).round(3),
            y_g: (y_raw * @scale_factor).round(3),
            z_g: (z_raw * @scale_factor).round(3)
          }
        end

        private

        # Configure sensor for measurement mode with specified range
        def configure_sensor(addr)
          # Set data format: range bits [1:0]
          # ±2g: 0b00, ±4g: 0b01, ±8g: 0b10, ±16g: 0b11
          range_bits = case @range
                       when 2 then 0b00
                       when 4 then 0b01
                       when 8 then 0b10
                       when 16 then 0b11
                       else raise ArgumentError, "Invalid range: #{@range}g (must be 2, 4, 8, or 16)"
                       end
          @i2c.write(addr, [range_bits], register: DATA_FORMAT_REG)

          # Enable measurement mode
          @i2c.write(addr, [MEASURE_BIT], register: POWER_CTL_REG)

          # Wait for sensor to stabilize
          sleep(0.01)
        end

        # Calculate scale factor for converting raw values to g
        # ADXL345 uses 10-bit resolution in full resolution mode
        # Scale factor: range / 512 (for 10-bit)
        def calculate_scale_factor(range)
          # In full resolution mode, scale is ~3.9 mg/LSB regardless of range
          # In fixed 10-bit mode, scale depends on range
          # Using simplified calculation: range / 512
          range / 512.0
        end

        # Convert unsigned 16-bit to signed 16-bit
        def to_signed16(val)
          val > 32_767 ? val - 65_536 : val
        end
      end
    end
  end
end
