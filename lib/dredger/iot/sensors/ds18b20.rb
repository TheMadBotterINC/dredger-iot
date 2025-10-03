# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # DS18B20 digital temperature sensor (1-Wire protocol)
      # Uses a provider interface to allow simulation in tests and hardware backends in production.
      class DS18B20 < BaseSensor
        # provider must respond to :read_temperature(device_id) -> Float (celsius)
        def initialize(device_id:, provider:, metadata: {})
          super(metadata: metadata)
          @device_id = device_id
          @provider = provider
        end

        def readings
          temp_c = @provider.read_temperature(@device_id)
          [reading(sensor_type: 'temperature', value: temp_c, unit: 'celsius')]
        end
      end
    end
  end
end
# EOF
