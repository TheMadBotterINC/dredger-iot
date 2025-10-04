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

# Create multiple sensors
sensors = [
  Dredger::IoT::Sensors::DHT22.new(
    pin_label: 'P9_12',
    provider: Dredger::IoT::Sensors::DHT22Provider.new(gpio_bus: gpio),
    metadata: { location: 'indoor', room: 'living_room' }
  ),
  Dredger::IoT::Sensors::BME280.new(
    i2c_addr: 0x76,
    provider: Dredger::IoT::Sensors::BME280Provider.new(i2c_bus: i2c),
    metadata: { location: 'outdoor', position: 'north_wall' }
  )
]

puts 'Multi-Sensor Environmental Monitor'
puts '=' * 60
puts "Monitoring #{sensors.size} sensors"
puts 'Poll interval: 60 seconds (±10% jitter)'
puts 'Press Ctrl+C to stop'
puts '=' * 60
puts

# Create scheduler with jitter to avoid synchronized polling spikes
scheduler = Dredger::IoT::Scheduler.periodic_with_jitter(
  base_interval: 60.0,
  jitter_ratio: 0.1
)

# Poll sensors continuously
begin
  scheduler.each_with_index do |interval, cycle|
    puts "\n[Cycle #{cycle + 1}] Waiting #{interval.round(2)}s..."
    sleep interval

    timestamp = Time.now.iso8601
    puts "\n#{timestamp}"
    puts '-' * 60

    sensors.each do |sensor|
      location = sensor.metadata[:location]
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
  end
rescue Interrupt
  puts "\n\nShutting down gracefully..."
ensure
  # Clean up resources
  gpio.close
  i2c.close
end

puts 'Monitor stopped.'
