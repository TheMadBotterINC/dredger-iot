# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::BH1750Provider do
  let(:i2c) { Dredger::IoT::Bus::I2C.new }
  let(:provider) { described_class.new(i2c_bus: i2c) }
  let(:addr) { 0x23 }

  before { allow(provider).to receive(:sleep) }

  describe '#read_lux' do
    it 'computes lux from raw 16-bit big-endian value' do
      # raw = 0x0078 = 120, lux = 120 / 1.2 = 100.0
      allow(i2c).to receive(:read).with(addr, 2).and_return([0x00, 0x78])
      result = provider.read_lux(addr)

      expect(result).to be_within(0.1).of(100.0)
    end

    it 'returns 0.0 for zero reading' do
      allow(i2c).to receive(:read).with(addr, 2).and_return([0x00, 0x00])
      result = provider.read_lux(addr)

      expect(result).to eq(0.0)
    end

    it 'handles high lux values' do
      # raw = 0xFFFF = 65535, lux = 65535 / 1.2 = 54612.5
      allow(i2c).to receive(:read).with(addr, 2).and_return([0xFF, 0xFF])
      result = provider.read_lux(addr)

      expect(result).to be_within(0.1).of(54_612.5)
    end
  end
end
