# frozen_string_literal: true

module Dredger
  module IoT
    module Bus
      module Auto
        module_function

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def gpio(prefer: :auto, chip: 'gpiochip0', active_low: false)
          pref = prefer_from_env(ENV.fetch('DREDGER_IOT_GPIO_BACKEND', nil), prefer)
          case pref
          when :simulation
            Dredger::IoT::Bus::GPIO.new
          when :libgpiod
            begin
              safe_require('dredger/iot/bus/gpio_libgpiod')
              safe_require('dredger/iot/bus/gpio_label_adapter')
              raw = Dredger::IoT::Bus::GpioLibgpiod.new(chip: chip, active_low: active_low)
              backend = Dredger::IoT::Bus::GPIOLabelAdapter.new(backend: raw)
              Dredger::IoT::Bus::GPIO.new(backend: backend)
            rescue LoadError
              Dredger::IoT::Bus::GPIO.new
            end
          else # :auto
            if File.exist?('/dev/gpiochip0')
              begin
                safe_require('dredger/iot/bus/gpio_libgpiod')
                safe_require('dredger/iot/bus/gpio_label_adapter')
                raw = Dredger::IoT::Bus::GpioLibgpiod.new(chip: chip, active_low: active_low)
                backend = Dredger::IoT::Bus::GPIOLabelAdapter.new(backend: raw)
                return Dredger::IoT::Bus::GPIO.new(backend: backend)
              rescue LoadError
                # fallthrough
              end
            end
            Dredger::IoT::Bus::GPIO.new
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        # rubocop:disable Metrics/MethodLength
        def i2c(prefer: :auto, bus_path: '/dev/i2c-1')
          pref = prefer_from_env(ENV.fetch('DREDGER_IOT_I2C_BACKEND', nil), prefer)
          case pref
          when :simulation
            Dredger::IoT::Bus::I2C.new
          when :linux
            begin
              safe_require('dredger/iot/bus/i2c_linux')
              backend = Dredger::IoT::Bus::I2cLinux.new(bus_path: bus_path)
              Dredger::IoT::Bus::I2C.new(backend: backend)
            rescue LoadError
              Dredger::IoT::Bus::I2C.new
            end
          else # :auto
            if File.exist?(bus_path)
              begin
                safe_require('dredger/iot/bus/i2c_linux')
                backend = Dredger::IoT::Bus::I2cLinux.new(bus_path: bus_path)
                return Dredger::IoT::Bus::I2C.new(backend: backend)
              rescue LoadError
                # fallthrough
              end
            end
            Dredger::IoT::Bus::I2C.new
          end
        end
        # rubocop:enable Metrics/MethodLength

        def prefer_from_env(env_value, default)
          case env_value&.downcase
          when 'simulation' then :simulation
          when 'libgpiod' then :libgpiod
          when 'linux' then :linux
          else default
          end
        end

        def safe_require(path)
          require path
        end
      end
    end
  end
end
# EOF
