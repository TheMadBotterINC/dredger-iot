# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Bus::Auto do
  before do
    @orig_gpio = ENV['DREDGER_IOT_GPIO_BACKEND']
    @orig_i2c = ENV['DREDGER_IOT_I2C_BACKEND']
  end

  after do
    ENV['DREDGER_IOT_GPIO_BACKEND'] = @orig_gpio
    ENV['DREDGER_IOT_I2C_BACKEND'] = @orig_i2c
  end

  it 'returns simulation GPIO when requested' do
    bus = described_class.gpio(prefer: :simulation)
    backend = bus.instance_variable_get(:@backend)
    expect(backend).to be_a(Dredger::IoT::Bus::GPIO::Simulation)
  end

  it 'falls back to simulation if libgpiod load fails in auto mode' do
    allow(File).to receive(:exist?).with('/dev/gpiochip0').and_return(true)
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/gpio_libgpiod').and_raise(LoadError)
    bus = described_class.gpio(prefer: :auto)
    backend = bus.instance_variable_get(:@backend)
    expect(backend).to be_a(Dredger::IoT::Bus::GPIO::Simulation)
  end

  it 'returns simulation I2C when requested' do
    bus = described_class.i2c(prefer: :simulation)
    backend = bus.instance_variable_get(:@backend)
    expect(backend).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end

  it 'falls back to simulation if linux i2c load fails in auto mode' do
    allow(File).to receive(:exist?).with('/dev/i2c-1').and_return(true)
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/i2c_linux').and_raise(LoadError)
    bus = described_class.i2c(prefer: :auto, bus_path: '/dev/i2c-1')
    backend = bus.instance_variable_get(:@backend)
    expect(backend).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end

  it 'respects env vars to force simulation' do
    ENV['DREDGER_IOT_GPIO_BACKEND'] = 'simulation'
    ENV['DREDGER_IOT_I2C_BACKEND'] = 'simulation'
    bus_gpio = described_class.gpio
    bus_i2c = described_class.i2c
    expect(bus_gpio.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::GPIO::Simulation)
    expect(bus_i2c.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end
end