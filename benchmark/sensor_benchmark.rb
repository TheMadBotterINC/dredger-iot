#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dredger/iot'
require 'benchmark'

# Sensor Polling Performance Benchmark
# Measures sensor reading speeds

puts 'Sensor Polling Performance Benchmark'
puts '=' * 60
puts

# Set up backends with simulation
ENV['DREDGER_IOT_GPIO_BACKEND'] = 'simulation'
ENV['DREDGER_IOT_I2C_BACKEND'] = 'simulation'

gpio = Dredger::IoT::Bus::Auto.gpio
i2c = Dredger::IoT::Bus::Auto.i2c

# Create sensors
dht22 = Dredger::IoT::Sensors::DHT22.new(
  pin_label: 'P9_12',
  provider: Dredger::IoT::Sensors::DHT22Provider.new(gpio_bus: gpio)
)

bme280 = Dredger::IoT::Sensors::BME280.new(
  i2c_addr: 0x76,
  provider: Dredger::IoT::Sensors::BME280Provider.new(i2c_bus: i2c)
)

ITERATIONS = 1000

puts "Running #{ITERATIONS} iterations per sensor..."
puts

Benchmark.bm(30) do |x|
  x.report('DHT22 readings:') do
    ITERATIONS.times do
      dht22.readings
    end
  end

  x.report('BME280 readings:') do
    ITERATIONS.times do
      bme280.readings
    end
  end

  x.report('Multi-sensor poll (2 sensors):') do
    sensors = [dht22, bme280]
    ITERATIONS.times do
      sensors.each(&:readings)
    end
  end
end

gpio.close
i2c.close

puts
puts 'Note: Results are for simulation backend.'
puts 'Hardware sensor readings will be slower due to actual I/O.'
puts
puts 'Typical real-world timing:'
puts '  DHT22:  ~250ms per reading (hardware limitation)'
puts '  BME280: ~10-50ms depending on oversampling settings'
