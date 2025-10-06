# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # Hardware provider for YF-S201 water flow sensor via GPIO pulse counting.
      # Datasheet: https://www.hobbytronics.co.uk/download/YF-S201.pdf
      #
      # Key features:
      # - Hall effect sensor with digital output
      # - Flow rate range: 1-30 L/min
      # - Pulse frequency: ~4.5 * flow_rate (L/min)
      # - Working voltage: 5V DC
      # - Thread size: G1/2" (DN15)
      #
      # Calibration:
      # - Frequency (Hz) = 7.5 * flow rate (L/min) (official spec)
      # - In practice: F = K * Q where K ≈ 4.5-7.5 depending on unit
      # - Default calibration factor: 7.5 (pulses per liter)
      class YFS201Provider
        # gpio_bus: a GPIO bus interface (e.g., Dredger::IoT::Bus::Auto.gpio)
        # calibration_factor: pulses per liter (default: 7.5 for YF-S201)
        def initialize(gpio_bus:, calibration_factor: 7.5)
          @gpio = gpio_bus
          @calibration_factor = calibration_factor
        end

        # Read flow rate by counting pulses over the specified duration.
        # Returns { flow_rate_lpm: Float, pulses: Integer }
        #
        # @param pin_label [String] GPIO pin label (e.g., 'P9_12', 'GPIO17')
        # @param duration [Float] Sampling duration in seconds
        def read_flow_rate(pin_label, duration)
          # Configure pin as input
          @gpio.set_direction(pin_label, :in)

          # Count rising edge pulses over the duration
          pulses = count_pulses(pin_label, duration)

          # Calculate flow rate in L/min
          # pulses_per_second = pulses / duration
          # liters_per_second = pulses_per_second / calibration_factor
          # liters_per_minute = liters_per_second * 60
          flow_rate_lpm = (pulses / duration / @calibration_factor * 60.0).round(2)

          {
            flow_rate_lpm: flow_rate_lpm,
            pulses: pulses
          }
        end

        private

        # Count rising edge transitions on the pin over the specified duration.
        # This is a simplified implementation - production code should use:
        # - Hardware interrupts (kernel module or pigpio daemon)
        # - Edge detection via sysfs GPIO (epoll)
        # - High-priority thread for accurate timing
        def count_pulses(pin_label, duration)
          pulses = 0
          last_state = @gpio.read(pin_label)
          start_time = Time.now

          # Poll GPIO at high frequency to detect edges
          # Note: This is CPU-intensive and timing-dependent
          # For production, use hardware interrupts or kernel GPIO edge detection
          while Time.now - start_time < duration
            current_state = @gpio.read(pin_label)
            
            # Detect rising edge (0 -> 1 transition)
            if current_state == 1 && last_state == 0
              pulses += 1
            end
            
            last_state = current_state
            
            # Small sleep to reduce CPU usage
            # Trade-off: Higher sleep = lower CPU, but may miss pulses
            # For accurate counting, use interrupts instead
            sleep(0.0001) # 0.1ms
          end

          pulses
        end
      end
    end
  end
end
