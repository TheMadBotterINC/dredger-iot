#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dredger/iot'

# Example: Read temperature and humidity from SHT31 (I2C)
# Env overrides:
#   SHT31_ADDR   (default: 0x44)
#   INTERVAL_SEC (default: 2)

addr_hex = ENV['SHT31_ADDR'] || '0x44'
addr = addr_hex.to_i(16)
interval = (ENV['INTERVAL_SEC'] || '2').to_f

i2c = Dredger::IoT::Bus::Auto.i2c
provider = Dredger::IoT::Sensors::SHT31Provider.new(i2c_bus: i2c)
sensor = Dredger::IoT::Sensors::SHT31.new(i2c_addr: addr, provider: provider, metadata: { sensor: 'sht31' })

puts "Reading SHT31 on addr=#{addr_hex} every #{interval}s (Ctrl+C to stop)"
loop do
  rs = sensor.readings
  ts = Time.now.utc.iso8601
  rs.each do |r|
    puts "#{ts} #{r.sensor_type}=#{r.value} #{r.unit}"
  end
  sleep interval
end
