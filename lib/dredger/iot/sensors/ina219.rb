# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # INA219 current/voltage/power monitor (I2C)
      # Provider must respond to :read_measurements(addr) -> { bus_voltage_v:, current_ma:, shunt_voltage_mv: }
      class INA219 < BaseSensor
        def initialize(i2c_addr:, provider:, metadata: {})
          super(metadata: metadata)
          @i2c_addr = i2c_addr
          @provider = provider
        end

        def readings
          m = @provider.read_measurements(@i2c_addr)
          [
            reading(sensor_type: 'bus_voltage', value: m[:bus_voltage_v], unit: 'V'),
            reading(sensor_type: 'current', value: m[:current_ma], unit: 'mA')
          ]
        end
      end
    end
  end
end
