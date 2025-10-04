#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dredger/iot'
require 'benchmark'

# GPIO Performance Benchmark
# Measures read/write speeds for GPIO operations

puts 'GPIO Performance Benchmark'
puts '=' * 60
puts

# Set up GPIO with simulation backend
ENV['DREDGER_IOT_GPIO_BACKEND'] = 'simulation'
gpio = Dredger::IoT::Bus::Auto.gpio
pin = 'P9_12'

gpio.set_direction(pin, :out)

ITERATIONS = 10_000

puts "Running #{ITERATIONS} iterations..."
puts

Benchmark.bm(25) do |x|
  x.report('GPIO write operations:') do
    ITERATIONS.times do |i|
      gpio.write(pin, i % 2)
    end
  end

  gpio.set_direction(pin, :in)

  x.report('GPIO read operations:') do
    ITERATIONS.times do
      gpio.read(pin)
    end
  end

  gpio.set_direction(pin, :out)

  x.report('GPIO direction changes:') do
    ITERATIONS.times do |i|
      gpio.set_direction(pin, i.even? ? :out : :in)
    end
  end
end

gpio.close

puts
puts 'Note: Results are for simulation backend.'
puts 'Hardware backend performance will vary based on the platform.'
