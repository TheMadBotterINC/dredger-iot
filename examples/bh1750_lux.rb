#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dredger/iot'

# Example: Read ambient light (lux) from BH1750 (I2C)
# Env overrides:
#   BH1750_ADDR  (default: 0x23)
#   INTERVAL_SEC (default: 2)

addr_hex = ENV['BH1750_ADDR'] || '0x23'
addr = addr_hex.to_i(16)
interval = (ENV['INTERVAL_SEC'] || '2').to_f

i2c = Dredger::IoT::Bus::Auto.i2c
provider = Dredger::IoT::Sensors::BH1750Provider.new(i2c_bus: i2c)
sensor = Dredger::IoT::Sensors::BH1750.new(i2c_addr: addr, provider: provider, metadata: { sensor: 'bh1750' })

puts "Reading BH1750 on addr=#{addr_hex} every #{interval}s (Ctrl+C to stop)"
loop do
  rs = sensor.readings
  ts = Time.now.utc.iso8601
  r = rs.first
  puts "#{ts} lux=#{r.value}"
  sleep interval
end