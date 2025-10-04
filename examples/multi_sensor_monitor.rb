#!/usr/bin/env ruby
# frozen_string_literal: true

# Multi-Sensor Monitoring with Scheduled Polling
# Usage: ruby examples/multi_sensor_monitor.rb

require 'bundler/setup'
require 'dredger/iot'
require 'json'

# Set up buses
gpio = Dredger::IoT::Bus::Auto.gpio
i2c = Dredger::IoT::Bus::Auto.i2c

# If running with the I2C simulation backend, seed BME280 registers so readings look realistic.
# This seeds:
# - Chip ID (0xD0 = 0x60)
# - Calibration blocks at 0x88-0xA1 (26 bytes) and 0xE1-0xE7 (7 bytes)
# - A single set of raw measurement bytes at 0xF7-0xFE (pressure, temperature, humidity)
backend = i2c.instance_variable_get(:@backend)
if backend.is_a?(Dredger::IoT::Bus::I2C::Simulation)
  addr = 0x76

  # Chip ID
  backend.seed(addr, 0xD0, [0x60])

  # Calibration data from a plausible BME280 example (little-endian where applicable)
  # 0x88-0xA1 (26 bytes): dig_T1..dig_P9 plus dig_H1 at last byte
  calib1 = [
    0x90, 0x6B, 0x33, 0x67, 0x18, 0xFC, 0x6D, 0x8E,
    0x63, 0xD6, 0xD0, 0x0B, 0x27, 0x0B, 0x8C, 0x00,
    0xF9, 0xFF, 0x9C, 0x3C, 0x08, 0xC7, 0x70, 0x17,
    0x00, 0x4B # dig_H1 = 0x4B (75)
  ]
  backend.seed(addr, 0x88, calib1)

  # 0xE1-0xE7 (7 bytes): dig_H2..dig_H6 with split-nibble packing for H4/H5
  # dig_H2 = 0x016A (362), dig_H3 = 0x00, dig_H4 = 0x14E (334), dig_H5 = 0x032 (50), dig_H6 = 0x1E (30)
  calib2 = [0x6A, 0x01, 0x00, 0x14, 0x2E, 0x03, 0x1E]
  backend.seed(addr, 0xE1, calib2)

  # Raw measurement data at 0xF7..0xFE: pressure[3], temperature[3], humidity[2]
  # These values are chosen to yield reasonable compensated outputs with the above calibration.
  raw = [0x64, 0x80, 0x00, 0x80, 0x00, 0x00, 0x66, 0x00]
  backend.seed(addr, 0xF7, raw)
end

# Create multiple sensors
sensors = [
  {
    object: Dredger::IoT::Sensors::DHT22.new(
      pin_label: 'P9_12',
      provider: Dredger::IoT::Sensors::DHT22Provider.new(gpio_bus: gpio)
    ),
    metadata: { location: 'indoor', room: 'living_room' }
  },
  {
    object: Dredger::IoT::Sensors::BME280.new(
      i2c_addr: 0x76,
      provider: Dredger::IoT::Sensors::BME280Provider.new(i2c_bus: i2c)
    ),
    metadata: { location: 'outdoor', position: 'north_wall' }
  }
]

puts 'Multi-Sensor Environmental Monitor'
puts '=' * 60
puts "Monitoring #{sensors.size} sensors"

# Allow quick demo runs via environment variables
base_interval = (ENV['DREDGER_IOT_EXAMPLE_INTERVAL'] || '60.0').to_f
jitter_ratio  = (ENV['DREDGER_IOT_EXAMPLE_JITTER'] || '0.1').to_f
max_cycles    = ENV['DREDGER_IOT_EXAMPLE_CYCLES']&.to_i
max_cycles    = nil if max_cycles&.zero?

puts "Poll interval: #{base_interval} seconds (±#{(jitter_ratio * 100).round}% jitter)"
puts 'Press Ctrl+C to stop'
puts '=' * 60
puts

# Create scheduler with jitter to avoid synchronized polling spikes
scheduler = Dredger::IoT::Scheduler.periodic_with_jitter(
  base_interval: base_interval,
  jitter_ratio: jitter_ratio
)

# Poll sensors continuously
begin
  scheduler.each_with_index do |interval, cycle|
    puts "\n[Cycle #{cycle + 1}] Waiting #{interval.round(2)}s..."
    sleep interval

    timestamp = Time.now.iso8601
    puts "\n#{timestamp}"
    puts '-' * 60

    sensors.each do |sensor_data|
      sensor = sensor_data[:object]
      metadata = sensor_data[:metadata]
      location = metadata[:location]
      puts "\n#{location.upcase}:"

      begin
        readings = sensor.readings

        readings.each do |reading|
          value = reading.value.is_a?(Float) ? reading.value.round(2) : reading.value
          puts "  #{reading.sensor_type}: #{value} #{reading.unit}"
        end

        # Optional: Log to JSON file
        {
          timestamp: timestamp,
          location: location,
          metadata: metadata,
          readings: readings.map do |r|
            {
              type: r.sensor_type,
              value: r.value,
              unit: r.unit
            }
          end
        }

        # Uncomment to enable JSON logging:
        # File.open('sensor_log.json', 'a') do |f|
        #   f.puts log_entry.to_json
        # end
      rescue StandardError => e
        puts "  ERROR: #{e.message}"
      end
    end

    puts '-' * 60

    # Stop after configured number of cycles (if provided)
    break if max_cycles && (cycle + 1) >= max_cycles
  end
rescue Interrupt
  puts "\n\nShutting down gracefully..."
end

puts 'Monitor stopped.'
