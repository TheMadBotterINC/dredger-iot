#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dredger/iot'

# Example: Read ambient light (lux) from TSL2561 (I2C)
# Env overrides:
#   TSL2561_ADDR (default: 0x39)
#   INTERVAL_SEC (default: 2)

addr_hex = ENV['TSL2561_ADDR'] || '0x39'
addr = addr_hex.to_i(16)
interval = (ENV['INTERVAL_SEC'] || '2').to_f

i2c = Dredger::IoT::Bus::Auto.i2c
provider = Dredger::IoT::Sensors::TSL2561Provider.new(i2c_bus: i2c)
sensor = Dredger::IoT::Sensors::TSL2561.new(i2c_addr: addr, provider: provider, metadata: { sensor: 'tsl2561' })

puts "Reading TSL2561 on addr=#{addr_hex} every #{interval}s (Ctrl+C to stop)"
loop do
  rs = sensor.readings
  ts = Time.now.utc.iso8601
  r = rs.first
  puts "#{ts} lux=#{r.value}"
  sleep interval
end
