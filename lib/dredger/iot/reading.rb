# frozen_string_literal: true

module Dredger
  module IoT
    # Immutable, normalized sensor reading
    Reading = Struct.new(
      :sensor_type, :value, :unit, :recorded_at, :calibrated, :accuracy, :metadata,
      keyword_init: true
    ) do
      def initialize(**kwargs)
        super
        freeze
      end

      def to_h
        {
          sensor_type: sensor_type,
          value: value,
          unit: unit,
          recorded_at: recorded_at,
          calibrated: calibrated,
          accuracy: accuracy,
          metadata: metadata
        }
      end
    end
  end
end