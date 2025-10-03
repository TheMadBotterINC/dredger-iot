#!/usr/bin/env ruby
# frozen_string_literal: true

# DS18B20 Waterproof Temperature Sensor Example
# Usage: ruby examples/ds18b20_temperature.rb

require 'bundler/setup'
require 'dredger/iot'

# Set up DS18B20 provider (uses kernel w1-gpio module)
provider = Dredger::IoT::Sensors::DS18B20Provider.new

puts 'DS18B20 Temperature Sensor Example'
puts '=' * 50

# List all connected DS18B20 devices
devices = provider.list_devices
puts "Found #{devices.size} DS18B20 device(s):"
devices.each { |device_id| puts "  - #{device_id}" }
puts

if devices.empty?
  puts 'No DS18B20 devices found!'
  puts
  puts 'Make sure:'
  puts '  1. w1-gpio and w1-therm kernel modules are loaded'
  puts '  2. DS18B20 is properly wired with 4.7kΩ pull-up resistor'
  puts '  3. Check /sys/bus/w1/devices/ for device IDs'
  exit 1
end

# Use the first device found
device_id = devices.first

# Create sensor instance
sensor = Dredger::IoT::Sensors::DS18B20.new(
  device_id: device_id,
  provider: provider,
  metadata: { location: 'water_tank', sensor_type: 'waterproof' }
)

puts "Reading from device: #{device_id}"
puts "Location: #{sensor.metadata[:location]}"
puts '=' * 50
puts

# Take continuous readings
begin
  puts 'Press Ctrl+C to stop'
  puts

  loop do
    reading = sensor.readings.first
    
    temp_c = reading.value.round(2)
    temp_f = (temp_c * 9.0 / 5.0 + 32).round(2)
    
    timestamp = reading.timestamp.strftime('%H:%M:%S')
    
    puts "[#{timestamp}] Temperature: #{temp_c}°C (#{temp_f}°F)"
    
    sleep 2
  end
rescue Interrupt
  puts "\n\nStopped."
end
