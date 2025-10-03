# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # MCP9808 high-accuracy I2C temperature sensor
      # Provider must respond to :read_temperature(addr) -> Float (celsius)
      class MCP9808 < BaseSensor
        def initialize(i2c_addr:, provider:, metadata: {})
          super(metadata: metadata)
          @i2c_addr = i2c_addr
          @provider = provider
        end

        def readings
          temp_c = @provider.read_temperature(@i2c_addr)
          [reading(sensor_type: 'temperature', value: temp_c, unit: 'celsius')]
        end
      end
    end
  end
end
# EOF
