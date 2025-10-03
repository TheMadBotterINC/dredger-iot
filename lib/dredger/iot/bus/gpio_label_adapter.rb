# frozen_string_literal: true

module Dredger
  module IoT
    module Bus
      # Adapts label strings (e.g. 'P9_12') to PinRef with chip:line for libgpiod backends
      class GPIOLabelAdapter
        def initialize(backend:, mapper: Dredger::IoT::Pins::Beaglebone)
          @backend = backend
          @mapper = mapper
        end

        def set_direction(pin, direction)
          @backend.set_direction(resolve(pin), direction)
        end

        def write(pin, value)
          @backend.write(resolve(pin), value)
        end

        def read(pin)
          @backend.read(resolve(pin))
        end

        private

        def resolve(pin)
          # Already a PinRef with line
          return pin if pin.respond_to?(:line) && !pin.line.nil?
          # Numeric line
          return Integer(pin) if pin.is_a?(Integer) || pin.to_s =~ /^\d+$/
          # Beaglebone-style label
          return @mapper.resolve_label_to_pinref(pin) if @mapper.respond_to?(:resolve_label_to_pinref)

          raise ArgumentError, 'Unsupported pin format'
        end
      end
    end
  end
end
# EOF
