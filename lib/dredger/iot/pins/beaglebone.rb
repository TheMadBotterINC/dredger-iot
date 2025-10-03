# frozen_string_literal: true

module Dredger
  module IoT
    module Pins
      # Beaglebone header label mapping placeholder.
      # Provides validation and PinRef objects; actual chip:line resolution is done at runtime by the agent or a backend.
      class Beaglebone
        PinRef = Struct.new(:label, :chip, :line, keyword_init: true) do
          def to_s
            chip && line ? "#{label}(chip#{chip}:#{line})" : label.to_s
          end
        end

        KNOWN_LABELS = (
          (0..46).map { |n| "P8_#{n}" } + (0..46).map { |n| "P9_#{n}" }
        ).freeze

        def self.valid_label?(label)
          KNOWN_LABELS.include?(label.to_s)
        end

        def self.resolve(label)
          raise ArgumentError, "Unknown pin label: #{label}" unless valid_label?(label)

          PinRef.new(label: label.to_s, chip: nil, line: nil)
        end
      end
    end
  end
end