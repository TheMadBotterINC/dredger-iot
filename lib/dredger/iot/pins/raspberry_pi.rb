# frozen_string_literal: true

module Dredger
  module IoT
    module Pins
      # Raspberry Pi header/BCM label mapping.
      # Supports labels like:
      # - GPIO17, BCM17
      # - PIN11 (a.k.a. BOARD11)
      class RaspberryPi
        PinRef = Struct.new(:label, :chip, :line, keyword_init: true) do
          def to_s
            chip && line ? "#{label}(chip#{chip}:#{line})" : label.to_s
          end
        end

        # Subset of BOARD pin to BCM mapping for common usable GPIOs on 40-pin header
        BOARD_TO_BCM = {
          3 => 2, 5 => 3, 7 => 4, 8 => 14, 10 => 15, 11 => 17, 12 => 18, 13 => 27,
          15 => 22, 16 => 23, 18 => 24, 19 => 10, 21 => 9, 22 => 25, 23 => 11,
          24 => 8, 26 => 7, 29 => 5, 31 => 6, 32 => 12, 33 => 13, 35 => 19,
          36 => 16, 37 => 26, 38 => 20, 40 => 21
        }.freeze

        # Accept variants like GPIO17, BCM17, PIN11, BOARD11
        def self.valid_label?(label)
          s = label.to_s.upcase
          return true if s.match?(/^(GPIO|BCM)\d+$/)
          return true if s.match?(/^(PIN|BOARD)\d+$/)

          false
        end

        def self.resolve_label_to_pinref(label)
          s = label.to_s.upcase
          if s =~ /^(GPIO|BCM)(\d+)$/
            bcm = Regexp.last_match(2).to_i
            return PinRef.new(label: label.to_s, chip: 0, line: bcm)
          end

          if s =~ /^(PIN|BOARD)(\d+)$/
            board = Regexp.last_match(2).to_i
            bcm = BOARD_TO_BCM[board]
            raise ArgumentError, "Unknown/unsupported board pin: #{label}" if bcm.nil?

            return PinRef.new(label: label.to_s, chip: 0, line: bcm)
          end

          raise ArgumentError, "Unknown Raspberry Pi pin label: #{label}"
        end
      end
    end
  end
end
