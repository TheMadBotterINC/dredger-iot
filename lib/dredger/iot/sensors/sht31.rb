# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # SHT31 temperature/humidity sensor (I2C)
      # Provider must respond to :read_measurements(addr) -> { temperature_c:, humidity: }
      class SHT31 < BaseSensor
        def initialize(i2c_addr:, provider:, metadata: {})
          super(metadata: metadata)
          @i2c_addr = i2c_addr
          @provider = provider
        end

        def readings
          m = @provider.read_measurements(@i2c_addr)
          [
            reading(sensor_type: 'temperature', value: m[:temperature_c], unit: 'celsius'),
            reading(sensor_type: 'humidity', value: m[:humidity], unit: '%')
          ]
        end
      end
    end
  end
end
