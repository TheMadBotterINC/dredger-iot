# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # SCD30 NDIR CO2 sensor with integrated temperature and humidity sensor
      # Measures CO2 concentration, temperature, and humidity
      # Uses a provider interface to allow simulation in tests and hardware backends in production.
      class SCD30 < BaseSensor
        # provider must respond to :read_measurements(i2c_addr) -> { co2_ppm:, temperature_c:, humidity: }
        def initialize(i2c_addr: 0x61, provider:, metadata: {})
          super(metadata: metadata)
          @i2c_addr = i2c_addr
          @provider = provider
        end

        def readings
          sample = @provider.read_measurements(@i2c_addr)
          [
            reading(sensor_type: 'co2', value: sample[:co2_ppm], unit: 'ppm'),
            reading(sensor_type: 'temperature', value: sample[:temperature_c], unit: 'celsius'),
            reading(sensor_type: 'humidity', value: sample[:humidity], unit: '%')
          ]
        end
      end
    end
  end
end
