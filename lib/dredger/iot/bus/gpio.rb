# frozen_string_literal: true

module Dredger
  module IoT
    module Bus
      # Simple GPIO bus with pluggable backend. Defaults to Simulation.
      class GPIO
        def initialize(backend: nil)
          @backend = backend || Simulation.new
        end

        def set_direction(pin_label, direction)
          @backend.set_direction(pin_label, direction)
        end

        def write(pin_label, value)
          @backend.write(pin_label, value)
        end

        def read(pin_label)
          @backend.read(pin_label)
        end

        # Simulation backend for tests/development
        class Simulation
          def initialize
            @values = Hash.new(0)
            @directions = {}
          end

          def set_direction(pin_label, direction)
            raise ArgumentError, 'direction must be :in or :out' unless %i[in out].include?(direction)

            @directions[pin_label] = direction
          end

          def write(pin_label, value)
            raise ArgumentError, 'value must be 0 or 1' unless [0, 1, true, false].include?(value)
            raise 'pin not configured for :out' unless @directions[pin_label] == :out

            @values[pin_label] = [1, true].include?(value) ? 1 : 0
          end

          def read(pin_label)
            # If configured as input, just return last seen value (or default 0)
            @values[pin_label]
          end

          # Helpers for test injection
          def inject_input(pin_label, value)
            raise ArgumentError, 'value must be 0 or 1' unless [0, 1, true, false].include?(value)

            @values[pin_label] = [1, true].include?(value) ? 1 : 0
          end
        end
      end
    end
  end
end
