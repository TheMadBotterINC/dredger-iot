# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # BH1750 ambient light sensor (I2C)
      # Provider must respond to :read_lux(addr) -> Float (lux)
      class BH1750 < BaseSensor
        def initialize(i2c_addr:, provider:, metadata: {})
          super(metadata: metadata)
          @i2c_addr = i2c_addr
          @provider = provider
        end

        def readings
          lux = @provider.read_lux(@i2c_addr)
          [reading(sensor_type: 'illuminance', value: lux, unit: 'lux')]
        end
      end
    end
  end
end
