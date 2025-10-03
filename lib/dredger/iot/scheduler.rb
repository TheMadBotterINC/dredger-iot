# frozen_string_literal: true

module Dredger
  module IoT
    module Scheduler
      module_function

      # Returns an Enumerator yielding next sleep seconds with jitter each cycle
      # base_interval: Float seconds
      # jitter_ratio: 0.0..1.0 (fraction of base interval)
      def periodic_with_jitter(base_interval:, jitter_ratio: 0.1)
        raise ArgumentError, "base_interval must be > 0" unless base_interval.positive?
        raise ArgumentError, "jitter_ratio must be between 0.0 and 1.0" unless jitter_ratio.between?(0.0, 1.0)

        Enumerator.new do |y|
          loop do
            jitter = ((rand * 2) - 1) * (base_interval * jitter_ratio)
            y << [base_interval + jitter, 0.0].max
          end
        end
      end

      # Exponential backoff enumerator with max backoff and max attempts (or infinite if nil)
      def exponential_backoff(initial:, factor: 2.0, max: 60.0, attempts: nil)
        raise ArgumentError, "initial must be > 0" unless initial.positive?
        raise ArgumentError, "factor must be >= 1.0" unless factor >= 1.0
        raise ArgumentError, "max must be >= initial" unless max >= initial

        Enumerator.new do |y|
          i = 0
          current = initial
          loop do
            break if attempts && i >= attempts

            y << current
            current = [current * factor, max].min
            i += 1
          end
        end
      end
    end
  end
end
