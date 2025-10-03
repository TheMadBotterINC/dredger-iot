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

  it 'auto-selects simulation when no gpiochip device present' do
    allow(File).to receive(:exist?).with('/dev/gpiochip0').and_return(false)
    bus = described_class.gpio(prefer: :auto)
    expect(bus.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::GPIO::Simulation)
  end

  it 'falls back to simulation if libgpiod load fails in auto mode' do
    allow(File).to receive(:exist?).with('/dev/gpiochip0').and_return(true)
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/gpio_libgpiod').and_raise(LoadError)
    bus = described_class.gpio(prefer: :auto)
    backend = bus.instance_variable_get(:@backend)
    expect(backend).to be_a(Dredger::IoT::Bus::GPIO::Simulation)
  end

  it 'auto-selects libgpiod when device present and backend available' do
    allow(File).to receive(:exist?).with('/dev/gpiochip0').and_return(true)
    module Dredger; module IoT; module Bus; class GPIO_Libgpiod; def initialize(chip:, active_low:); end; end; end; end; end
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/gpio_libgpiod').and_return(true)
    bus = described_class.gpio(prefer: :auto)
    expect(bus.instance_variable_get(:@backend).class.name).to match(/GPIO_Libgpiod/)
  ensure
    Dredger::IoT::Bus.send(:remove_const, :GPIO_Libgpiod) if Dredger::IoT::Bus.const_defined?(:GPIO_Libgpiod)
  end

  it 'uses libgpiod backend when explicitly requested and available' do
    ENV['DREDGER_IOT_GPIO_BACKEND'] = 'libgpiod'
    # Define a dummy backend to avoid requiring actual library
    module Dredger; module IoT; module Bus; class GPIO_Libgpiod; def initialize(chip:, active_low:); end; end; end; end; end
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/gpio_libgpiod').and_return(true)
    bus = described_class.gpio
    backend = bus.instance_variable_get(:@backend)
    expect(backend.class.name).to match(/GPIO_Libgpiod/)
  ensure
    Dredger::IoT::Bus.send(:remove_const, :GPIO_Libgpiod) if Dredger::IoT::Bus.const_defined?(:GPIO_Libgpiod)
  end

  it 'falls back when prefer: :libgpiod is given but load fails' do
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/gpio_libgpiod').and_raise(LoadError)
    bus = described_class.gpio(prefer: :libgpiod)
    expect(bus.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::GPIO::Simulation)
  end

  it 'returns simulation I2C when requested' do
    bus = described_class.i2c(prefer: :simulation)
    backend = bus.instance_variable_get(:@backend)
    expect(backend).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end

  it 'auto-selects simulation when no i2c device present' do
    allow(File).to receive(:exist?).with('/dev/i2c-1').and_return(false)
    bus = described_class.i2c(prefer: :auto, bus_path: '/dev/i2c-1')
    expect(bus.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end

  it 'falls back to simulation if linux i2c load fails in auto mode' do
    allow(File).to receive(:exist?).with('/dev/i2c-1').and_return(true)
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/i2c_linux').and_raise(LoadError)
    bus = described_class.i2c(prefer: :auto, bus_path: '/dev/i2c-1')
    backend = bus.instance_variable_get(:@backend)
    expect(backend).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end

  it 'auto-selects linux i2c when device present and backend available' do
    allow(File).to receive(:exist?).with('/dev/i2c-1').and_return(true)
    module Dredger; module IoT; module Bus; class I2C_Linux; def initialize(bus_path:); end; end; end; end; end
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/i2c_linux').and_return(true)
    bus = described_class.i2c(prefer: :auto, bus_path: '/dev/i2c-1')
    expect(bus.instance_variable_get(:@backend).class.name).to match(/I2C_Linux/)
  ensure
    Dredger::IoT::Bus.send(:remove_const, :I2C_Linux) if Dredger::IoT::Bus.const_defined?(:I2C_Linux)
  end

  it 'uses linux i2c backend when explicitly requested and available' do
    ENV['DREDGER_IOT_I2C_BACKEND'] = 'linux'
    module Dredger; module IoT; module Bus; class I2C_Linux; def initialize(bus_path:); end; end; end; end; end
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/i2c_linux').and_return(true)
    bus = described_class.i2c(bus_path: '/dev/i2c-1')
    backend = bus.instance_variable_get(:@backend)
    expect(backend.class.name).to match(/I2C_Linux/)
  ensure
    Dredger::IoT::Bus.send(:remove_const, :I2C_Linux) if Dredger::IoT::Bus.const_defined?(:I2C_Linux)
  end

  it 'falls back when prefer: :linux is given but load fails' do
    allow(described_class).to receive(:safe_require).with('dredger/iot/bus/i2c_linux').and_raise(LoadError)
    bus = described_class.i2c(prefer: :linux, bus_path: '/dev/i2c-1')
    expect(bus.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end

  it 'respects env vars to force simulation' do
    ENV['DREDGER_IOT_GPIO_BACKEND'] = 'simulation'
    ENV['DREDGER_IOT_I2C_BACKEND'] = 'simulation'
    bus_gpio = described_class.gpio
    bus_i2c = described_class.i2c
    expect(bus_gpio.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::GPIO::Simulation)
    expect(bus_i2c.instance_variable_get(:@backend)).to be_a(Dredger::IoT::Bus::I2C::Simulation)
  end

  it 'maps env strings to symbols via prefer_from_env' do
    expect(described_class.prefer_from_env('simulation', :auto)).to eq(:simulation)
    expect(described_class.prefer_from_env('libgpiod', :auto)).to eq(:libgpiod)
    expect(described_class.prefer_from_env('linux', :auto)).to eq(:linux)
    expect(described_class.prefer_from_env(nil, :auto)).to eq(:auto)
  end
end
