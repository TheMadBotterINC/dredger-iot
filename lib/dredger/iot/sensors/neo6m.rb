# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # NEO-6M GPS module (UART/Serial)
      # Provides location, altitude, speed, and satellite information
      # Uses a provider interface to allow simulation in tests and hardware backends in production.
      class NEO6M < BaseSensor
        # provider must respond to :read_position(device) -> { latitude:, longitude:, altitude:, speed:, satellites: }
        def initialize(device: '/dev/ttyAMA0', provider:, metadata: {})
          super(metadata: metadata)
          @device = device
          @provider = provider
        end

        def readings
          sample = @provider.read_position(@device)
          [
            reading(sensor_type: 'latitude', value: sample[:latitude], unit: 'degrees'),
            reading(sensor_type: 'longitude', value: sample[:longitude], unit: 'degrees'),
            reading(sensor_type: 'altitude', value: sample[:altitude], unit: 'm'),
            reading(sensor_type: 'speed', value: sample[:speed], unit: 'km/h'),
            reading(
              sensor_type: 'gps_quality',
              value: sample[:satellites],
              unit: 'satellites',
              metadata: { fix_quality: sample[:fix_quality] }
            )
          ]
        end
      end
    end
  end
end
