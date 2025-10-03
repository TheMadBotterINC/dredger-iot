# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      class BaseSensor
        def initialize(metadata: {})
          @metadata = metadata
        end

        def readings
          raise NotImplementedError
        end

        private

        def reading(sensor_type:, value:, unit:, calibrated: true, accuracy: nil, recorded_at: Time.now.utc, metadata: {})
          Dredger::IoT::Reading.new(
            sensor_type: sensor_type,
            value: value,
            unit: unit,
            recorded_at: recorded_at,
            calibrated: calibrated,
            accuracy: accuracy,
            metadata: @metadata.merge(metadata)
          )
        end
      end
    end
  end
end