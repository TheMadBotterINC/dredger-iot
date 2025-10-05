# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for INA219 current/voltage monitor (I2C)
      # Simplified: computes current from shunt voltage and provided shunt resistance,
      # avoids calibration register dependency.
      class INA219Provider
        REG_SHUNT_VOLTAGE = 0x01
        REG_BUS_VOLTAGE = 0x02

        def initialize(i2c_bus:, shunt_resistance_ohms: 0.1)
          @i2c = i2c_bus
          @r_shunt = shunt_resistance_ohms.to_f
        end

        # Returns { bus_voltage_v: Float, current_ma: Float, shunt_voltage_mv: Float }
        def read_measurements(addr)
          shunt_raw = read_word(addr, REG_SHUNT_VOLTAGE, signed: true)
          bus_raw = read_word(addr, REG_BUS_VOLTAGE, signed: false)

          # Shunt voltage LSB = 10uV => mV = raw * 0.01
          shunt_mv = shunt_raw * 0.01
          # Current (mA) = (shunt_mv / R_ohms)
          current_ma = (@r_shunt.positive? ? (shunt_mv / @r_shunt) : 0.0)

          # Bus voltage: bits [15:3] * 4mV
          bus_voltage_v = ((bus_raw >> 3) * 0.004)

          {
            bus_voltage_v: bus_voltage_v,
            current_ma: current_ma,
            shunt_voltage_mv: shunt_mv
          }
        end

        private

        # Read 16-bit word
        # INA219 registers are big-endian; register reads may return bytes LSB-first
        def read_word(addr, reg, signed: false)
          bytes = @i2c.read(addr, 2, register: reg)
          val = (bytes[0] << 8) | bytes[1]
          if signed && val > 0x7FFF
            val - 0x1_0000
          else
            val
          end
        end
      end
    end
  end
end
