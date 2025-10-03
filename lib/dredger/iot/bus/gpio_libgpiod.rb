# frozen_string_literal: true

require 'ffi'

module Dredger
  module IoT
    module Bus
      # GPIO backend using libgpiod ctxless helpers. Requires chip name and line offset.
      class GpioLibgpiod
        module Lib
          extend FFI::Library

          ffi_lib %w[gpiod libgpiod]

          # int gpiod_ctxless_get_value(const char *device, unsigned int offset, bool active_low,
          #                             const char *consumer);
          attach_function :gpiod_ctxless_get_value, %i[string uint bool string], :int

          # int gpiod_ctxless_set_value(const char *device, unsigned int offset, int value, bool active_low,
          #                             const char *consumer);
          attach_function :gpiod_ctxless_set_value, %i[string uint int bool string], :int
        end

        CONSUMER = 'dredger-iot'

        def initialize(chip: 'gpiochip0', active_low: false)
          @chip = chip
          @active_low = !!active_low
        end

        # pin can be Integer line offset, or a PinRef with :line
        def read(pin)
          line = line_from(pin)
          val = Lib.gpiod_ctxless_get_value(@chip, line, @active_low, CONSUMER)
          raise IOError, 'gpiod get failed' if val.negative?

          val
        end

        def write(pin, value)
          line = line_from(pin)
          int_val = [1, true].include?(value) ? 1 : 0
          rc = Lib.gpiod_ctxless_set_value(@chip, line, int_val, @active_low, CONSUMER)
          raise IOError, 'gpiod set failed' if rc.negative?

          rc
        end

        # no-op; ctxless helpers configure as needed per call
        def set_direction(_pin, _direction); end

        private

        def line_from(pin)
          return pin.line if pin.respond_to?(:line) && !pin.line.nil?
          return Integer(pin) if pin.is_a?(Integer) || pin.to_s =~ /^\d+$/

          raise ArgumentError, 'pin must be Integer line offset or PinRef with line'
        end
      end
    end
  end
end
