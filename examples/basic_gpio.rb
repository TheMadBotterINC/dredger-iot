#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic GPIO example - blinking an LED
# Usage: ruby examples/basic_gpio.rb

require 'bundler/setup'
require 'dredger/iot'

# Set up GPIO bus (will auto-select libgpiod or simulation)
gpio = Dredger::IoT::Bus::Auto.gpio

# Configure pin P9_12 as output
pin = 'P9_12'
gpio.set_direction(pin, :out)

puts "Blinking LED on pin #{pin}..."
puts 'Press Ctrl+C to stop'

# Blink LED 10 times
begin
  10.times do |i|
    puts "Blink #{i + 1}: ON"
    gpio.write(pin, 1)
    sleep 0.5

    puts "Blink #{i + 1}: OFF"
    gpio.write(pin, 0)
    sleep 0.5
  end
ensure
  # Clean up
  gpio.write(pin, 0)
  gpio.close
end

puts "\nDone!"
