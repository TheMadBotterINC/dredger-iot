# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::TSL2561Provider do
  let(:i2c) { Dredger::IoT::Bus::I2C.new }
  let(:provider) { described_class.new(i2c_bus: i2c) }
  let(:addr) { 0x39 }

  before { allow(provider).to receive(:sleep) }

  describe '#read_lux' do
    it 'computes lux for low ratio (ratio <= 0.5)' do
      # ch0=1000, ch1=400 => ratio=0.4
      # lux = 0.0304*1000 - 0.062*1000*(0.4^1.4) = 30.4 - 19.14 = ~11.26
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8C).and_return([0xE8, 0x03]) # ch0=1000 LE
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8E).and_return([0x90, 0x01]) # ch1=400 LE

      result = provider.read_lux(addr)
      expect(result).to be_a(Float)
      expect(result).to be > 0.0
    end

    it 'computes lux for mid ratio (0.5 < ratio <= 0.61)' do
      # ch0=1000, ch1=550 => ratio=0.55
      # lux = 0.0224*1000 - 0.031*550 = 22.4 - 17.05 = 5.35
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8C).and_return([0xE8, 0x03])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8E).and_return([0x26, 0x02])

      result = provider.read_lux(addr)
      expect(result).to be_within(0.1).of(5.35)
    end

    it 'computes lux for high ratio (0.61 < ratio <= 0.80)' do
      # ch0=1000, ch1=700 => ratio=0.7
      # lux = 0.0128*1000 - 0.0153*700 = 12.8 - 10.71 = 2.09
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8C).and_return([0xE8, 0x03])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8E).and_return([0xBC, 0x02])

      result = provider.read_lux(addr)
      expect(result).to be_within(0.1).of(2.09)
    end

    it 'computes lux for very high ratio (0.80 < ratio <= 1.30)' do
      # ch0=1000, ch1=1000 => ratio=1.0
      # lux = 0.00146*1000 - 0.00112*1000 = 1.46 - 1.12 = 0.34
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8C).and_return([0xE8, 0x03])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8E).and_return([0xE8, 0x03])

      result = provider.read_lux(addr)
      expect(result).to be_within(0.01).of(0.34)
    end

    it 'returns 0.0 for saturated sensor (ratio > 1.30)' do
      # ch0=100, ch1=200 => ratio=2.0
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8C).and_return([0x64, 0x00])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8E).and_return([0xC8, 0x00])

      result = provider.read_lux(addr)
      expect(result).to eq(0.0)
    end

    it 'returns 0.0 when ch0 is zero' do
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8C).and_return([0x00, 0x00])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8E).and_return([0x00, 0x00])

      result = provider.read_lux(addr)
      expect(result).to eq(0.0)
    end

    it 'powers off the sensor after reading' do
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8C).and_return([0xE8, 0x03])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x8E).and_return([0x90, 0x01])
      allow(i2c).to receive(:write)

      provider.read_lux(addr)

      # Last write should be power off (0x00) to CONTROL register (0x80)
      expect(i2c).to have_received(:write).with(addr, [0x00], register: 0x80)
    end
  end
end
