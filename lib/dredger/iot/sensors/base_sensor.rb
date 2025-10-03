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

        def reading(sensor_type:, value:, unit:, **opts)
          Dredger::IoT::Reading.new(
            sensor_type: sensor_type,
            value: value,
            unit: unit,
            recorded_at: opts.fetch(:recorded_at, Time.now.utc),
            calibrated: opts.fetch(:calibrated, true),
            accuracy: opts[:accuracy],
            metadata: @metadata.merge(opts.fetch(:metadata, {}))
          )
        end
      end
    end
  end
end
