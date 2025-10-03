# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for BME280 temperature/humidity/pressure sensor over I2C.
      # Datasheet: https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme280-ds002.pdf
      #
      # Key registers:
      # - 0xD0: chip_id (should be 0x60 for BME280)
      # - 0xF4: ctrl_meas (mode, oversampling)
      # - 0xF5: config (standby, filter)
      # - 0xF7-0xFE: measurement data (pressure, temp, humidity)
      # - 0x88-0xA1, 0xE1-0xE7: calibration coefficients
      class BME280Provider
        CHIP_ID_REG = 0xD0
        CHIP_ID_EXPECTED = 0x60
        CTRL_MEAS_REG = 0xF4
        CONFIG_REG = 0xF5
        DATA_REG = 0xF7

        # Calibration coefficient registers
        CALIB_00_REG = 0x88 # dig_T1..dig_H1 start
        CALIB_26_REG = 0xE1 # dig_H2..dig_H6 start

        # i2c_bus: an I2C bus interface (e.g., Dredger::IoT::Bus::Auto.i2c)
        def initialize(i2c_bus:)
          @i2c = i2c_bus
        end

        # Read measurements from the BME280 at the given I2C address.
        # Returns { temperature_c: Float, humidity: Float, pressure_kpa: Float }
        def read_measurements(addr)
          # Verify chip ID
          chip_id = @i2c.read(addr, 1, register: CHIP_ID_REG).first
          raise IOError, "BME280 not found (chip_id=0x#{chip_id.to_s(16)})" unless chip_id == CHIP_ID_EXPECTED

          # Read calibration coefficients (needed for compensating raw data)
          calib = read_calibration(addr)

          # Configure sensor: forced mode, oversampling x1 for all
          # ctrl_meas: osrs_t[7:5]=001, osrs_p[4:2]=001, mode[1:0]=01 (forced)
          @i2c.write(addr, [0b00100101], register: CTRL_MEAS_REG)

          # Wait for measurement (typical 8ms for this config)
          sleep(0.01)

          # Read raw data: 8 bytes from 0xF7
          raw = @i2c.read(addr, 8, register: DATA_REG)

          # Parse raw values (20-bit pressure, 20-bit temp, 16-bit humidity)
          press_raw = (raw[0] << 12) | (raw[1] << 4) | (raw[2] >> 4)
          temp_raw = (raw[3] << 12) | (raw[4] << 4) | (raw[5] >> 4)
          hum_raw = (raw[6] << 8) | raw[7]

          # Compensate using calibration (simplified integer math from datasheet)
          temp_c = compensate_temperature(temp_raw, calib)
          humidity = compensate_humidity(hum_raw, calib, temp_c)
          pressure_pa = compensate_pressure(press_raw, calib, temp_c)

          {
            temperature_c: temp_c,
            humidity: humidity,
            pressure_kpa: pressure_pa / 1000.0
          }
        end

        private

        # Read calibration coefficients from sensor
        def read_calibration(addr)
          # Read 26 bytes from 0x88-0xA1 (dig_T1..dig_P9, dig_H1)
          calib1 = @i2c.read(addr, 26, register: CALIB_00_REG)
          # Read 7 bytes from 0xE1-0xE7 (dig_H2..dig_H6)
          calib2 = @i2c.read(addr, 7, register: CALIB_26_REG)

          # Parse calibration data (see datasheet for layout)
          {
            dig_t1: u16(calib1, 0),
            dig_t2: s16(calib1, 2),
            dig_t3: s16(calib1, 4),
            dig_p1: u16(calib1, 6),
            dig_p2: s16(calib1, 8),
            dig_p3: s16(calib1, 10),
            dig_p4: s16(calib1, 12),
            dig_p5: s16(calib1, 14),
            dig_p6: s16(calib1, 16),
            dig_p7: s16(calib1, 18),
            dig_p8: s16(calib1, 20),
            dig_p9: s16(calib1, 22),
            dig_h1: calib1[25],
            dig_h2: s16(calib2, 0),
            dig_h3: calib2[2],
            dig_h4: (calib2[3] << 4) | (calib2[4] & 0x0F),
            dig_h5: (calib2[5] << 4) | (calib2[4] >> 4),
            dig_h6: s8(calib2[6])
          }
        end

        # Compensate temperature (returns °C, also sets @t_fine for other compensations)
        def compensate_temperature(adc_t, calib)
          var1 = (((adc_t / 16_384.0) - (calib[:dig_t1] / 1024.0)) * calib[:dig_t2])
          var2 = ((((adc_t / 131_072.0) - (calib[:dig_t1] / 8192.0))**2) * calib[:dig_t3])
          @t_fine = (var1 + var2).to_i
          @t_fine / 5120.0
        end

        # Compensate humidity (returns %)
        def compensate_humidity(adc_h, calib, _temp_c)
          return 0.0 if @t_fine.nil?

          var_h = @t_fine - 76_800.0
          var_h = (adc_h - ((calib[:dig_h4] * 64.0) + (calib[:dig_h5] / 16_384.0 * var_h))) *
                  (calib[:dig_h2] / 65_536.0 * (1.0 + (calib[:dig_h6] / 67_108_864.0 * var_h *
                  (1.0 + (calib[:dig_h3] / 67_108_864.0 * var_h)))))
          var_h *= (1.0 - (calib[:dig_h1] * var_h / 524_288.0))
          var_h = 0.0 if var_h < 0.0
          var_h = 100.0 if var_h > 100.0
          var_h
        end

        # Compensate pressure (returns Pa)
        def compensate_pressure(adc_p, calib, _temp_c)
          var1 = (@t_fine / 2.0) - 64_000.0
          var2 = var1 * var1 * calib[:dig_p6] / 32_768.0
          var2 += var1 * calib[:dig_p5] * 2.0
          var2 = (var2 / 4.0) + (calib[:dig_p4] * 65_536.0)
          var1 = ((calib[:dig_p3] * var1 * var1 / 524_288.0) + (calib[:dig_p2] * var1)) / 524_288.0
          var1 = (1.0 + (var1 / 32_768.0)) * calib[:dig_p1]
          return 0.0 if var1.zero?

          pressure = 1_048_576.0 - adc_p
          pressure = (pressure - (var2 / 4096.0)) * 6250.0 / var1
          var1 = calib[:dig_p9] * pressure * pressure / 2_147_483_648.0
          var2 = pressure * calib[:dig_p8] / 32_768.0
          pressure + ((var1 + var2 + calib[:dig_p7]) / 16.0)
        end

        # Helper: read unsigned 16-bit from byte array
        def u16(bytes, offset)
          bytes[offset] | (bytes[offset + 1] << 8)
        end

        # Helper: read signed 16-bit from byte array
        def s16(bytes, offset)
          val = u16(bytes, offset)
          val > 32_767 ? val - 65_536 : val
        end

        # Helper: read signed 8-bit
        def s8(byte)
          byte > 127 ? byte - 256 : byte
        end
      end
    end
  end
end
