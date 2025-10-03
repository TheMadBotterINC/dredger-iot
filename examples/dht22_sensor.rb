#!/usr/bin/env ruby
# frozen_string_literal: true

# DHT22 Temperature/Humidity Sensor Example
# Usage: ruby examples/dht22_sensor.rb

require 'bundler/setup'
require 'dredger/iot'

# Set up GPIO bus and DHT22 provider
gpio = Dredger::IoT::Bus::Auto.gpio
provider = Dredger::IoT::Sensors::DHT22Provider.new(gpio_bus: gpio)

# Create sensor instance
sensor = Dredger::IoT::Sensors::DHT22.new(
  pin_label: 'P9_12',
  provider: provider,
  metadata: { location: 'greenhouse', zone: 'main' }
)

puts 'DHT22 Sensor Reading Example'
puts '=' * 50
puts "Location: #{sensor.metadata[:location]}"
puts "Zone: #{sensor.metadata[:zone]}"
puts '=' * 50
puts

# Take 5 readings with delays
5.times do |i|
  puts "Reading #{i + 1}:"
  
  begin
    readings = sensor.readings
    
    readings.each do |reading|
      puts "  #{reading.sensor_type.capitalize}: #{reading.value} #{reading.unit}"
      puts "    Timestamp: #{reading.timestamp}"
    end
  rescue StandardError => e
    puts "  Error: #{e.message}"
  end
  
  puts
  sleep 3 # DHT22 requires ~2 seconds between reads
end

puts 'Done!'
