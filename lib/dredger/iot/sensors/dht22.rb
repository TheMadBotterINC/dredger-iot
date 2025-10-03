# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # DHT22 humidity/temperature sensor (1-wire like GPIO)
      # Uses a provider interface to allow simulation in tests and hardware backends in production.
      class DHT22 < BaseSensor
        # provider must respond to :sample(pin_label) -> { humidity: Float, temperature_c: Float }
        def initialize(pin_label:, provider:, metadata: {})
          super(metadata: metadata)
          @pin_label = pin_label
          @provider = provider
        end

        def readings
          sample = @provider.sample(@pin_label)
          [
            reading(sensor_type: 'humidity', value: sample[:humidity], unit: '%'),
            reading(sensor_type: 'temperature', value: sample[:temperature_c], unit: 'celsius')
          ]
        end
      end
    end
  end
end
