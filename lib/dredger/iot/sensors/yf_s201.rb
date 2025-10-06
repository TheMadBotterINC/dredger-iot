# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # YF-S201 water flow sensor (hall effect pulse counter)
      # Measures liquid flow rate by counting pulses from hall effect sensor
      # Uses a provider interface to allow simulation in tests and hardware backends in production.
      class YFS201 < BaseSensor
        # provider must respond to :read_flow_rate(pin_label, duration) -> { flow_rate_lpm: Float, pulses: Integer }
        def initialize(pin_label:, provider:, sample_duration: 1.0, metadata: {})
          super(metadata: metadata)
          @pin_label = pin_label
          @provider = provider
          @sample_duration = sample_duration
        end

        def readings
          sample = @provider.read_flow_rate(@pin_label, @sample_duration)
          [
            reading(
              sensor_type: 'flow_rate',
              value: sample[:flow_rate_lpm],
              unit: 'L/min',
              metadata: { pulses: sample[:pulses], duration: @sample_duration }
            )
          ]
        end
      end
    end
  end
end
