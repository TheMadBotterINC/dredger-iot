# frozen_string_literal: true

module Dredger
  module IoT
    module Sensors
      # ADXL345 3-axis digital accelerometer sensor (I2C/SPI)
      # Measures acceleration/vibration in x, y, z axes
      # Uses a provider interface to allow simulation in tests and hardware backends in production.
      class ADXL345 < BaseSensor
        # provider must respond to :read_measurements(i2c_addr) -> { x_g:, y_g:, z_g: }
        def initialize(i2c_addr: 0x53, provider:, metadata: {})
          super(metadata: metadata)
          @i2c_addr = i2c_addr
          @provider = provider
        end

        def readings
          sample = @provider.read_measurements(@i2c_addr)
          [
            reading(sensor_type: 'acceleration_x', value: sample[:x_g], unit: 'g'),
            reading(sensor_type: 'acceleration_y', value: sample[:y_g], unit: 'g'),
            reading(sensor_type: 'acceleration_z', value: sample[:z_g], unit: 'g')
          ]
        end
      end
    end
  end
end
