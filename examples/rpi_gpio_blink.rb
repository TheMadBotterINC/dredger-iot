#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dredger/iot'

# Raspberry Pi GPIO blink example using GPIO17 by default.
# Connect an LED + resistor to GPIO17 (BCM17, header PIN11) and GND.
# Env overrides:
#   PIN_LABEL    (default: GPIO17)
#   INTERVAL_SEC (default: 0.5)
#   CYCLES       (default: 10)

pin_label = ENV['PIN_LABEL'] || 'GPIO17'
interval = (ENV['INTERVAL_SEC'] || '0.5').to_f
cycles = (ENV['CYCLES'] || '10').to_i

gpio = Dredger::IoT::Bus::Auto.gpio

gpio.set_direction(pin_label, :out)
puts "Blinking #{pin_label} for #{cycles} cycles at #{interval}s interval..."

cycles.times do |i|
  puts "Cycle #{i + 1}: ON"
  gpio.write(pin_label, 1)
  sleep interval
  puts "Cycle #{i + 1}: OFF"
  gpio.write(pin_label, 0)
  sleep interval
end

puts 'Done.'
