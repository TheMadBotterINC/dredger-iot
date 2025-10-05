#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dredger/iot'

# Example: Monitor bus voltage (V) and current (mA) using INA219 (I2C)
# Env overrides:
#   INA219_ADDR  (default: 0x40)
#   INA219_SHUNT (default: 0.1 ohms)
#   INTERVAL_SEC (default: 2)

addr_hex = ENV['INA219_ADDR'] || '0x40'
addr = addr_hex.to_i(16)
shunt = (ENV['INA219_SHUNT'] || '0.1').to_f
interval = (ENV['INTERVAL_SEC'] || '2').to_f

i2c = Dredger::IoT::Bus::Auto.i2c
provider = Dredger::IoT::Sensors::INA219Provider.new(i2c_bus: i2c, shunt_resistance_ohms: shunt)
metadata = { sensor: 'ina219', shunt_ohms: shunt }
sensor = Dredger::IoT::Sensors::INA219.new(i2c_addr: addr, provider: provider, metadata: metadata)

puts "Reading INA219 on addr=#{addr_hex} shunt=#{shunt}Ω every #{interval}s (Ctrl+C to stop)"
loop do
  rs = sensor.readings
  ts = Time.now.utc.iso8601
  vs = rs.find { |r| r.sensor_type == 'bus_voltage' }
  cs = rs.find { |r| r.sensor_type == 'current' }
  puts "#{ts} V=#{vs.value.round(3)} #{vs.unit}  I=#{cs.value.round(2)} #{cs.unit}"
  sleep interval
end
