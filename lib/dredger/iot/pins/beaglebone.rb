# frozen_string_literal: true

module Dredger
  module IoT
    module Pins
      # Beaglebone header label mapping placeholder.
      class Beaglebone
        PinRef = Pins::PinRef

        KNOWN_LABELS = (
          (0..46).map { |n| "P8_#{n}" } + (0..46).map { |n| "P9_#{n}" }
        ).freeze

        # Minimal built-in mapping for common pins. This can be extended.
        # Mapping format: 'P9_12' => [chip_number, line_offset]
        MAP = {
          'P9_12' => [1, 28],
          'P9_14' => [1, 18]
        }.freeze

        def self.valid_label?(label)
          KNOWN_LABELS.include?(label.to_s)
        end

        def self.resolve(label)
          raise ArgumentError, "Unknown pin label: #{label}" unless valid_label?(label)

          PinRef.new(label: label.to_s, chip: nil, line: nil)
        end

        # Returns [chip_name, line] or raises if unknown
        def self.chip_line_for(label)
          normalized = label.to_s.upcase
          raise ArgumentError, "Unknown pin label: #{label}" unless valid_label?(normalized)

          pair = MAP[normalized]
          raise ArgumentError, "No mapping for label: #{label}" if pair.nil?

          ["gpiochip#{pair[0]}", pair[1]]
        end

        # Returns PinRef with chip and line resolved (raises if unknown)
        def self.resolve_label_to_pinref(label)
          chip, line = chip_line_for(label)
          PinRef.new(label: label.to_s, chip: chip.sub('gpiochip', '').to_i, line: line)
        end
      end
    end
  end
end
