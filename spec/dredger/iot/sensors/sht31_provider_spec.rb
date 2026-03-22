# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::SHT31Provider do
  let(:i2c) { Dredger::IoT::Bus::I2C.new }
  let(:provider) { described_class.new(i2c_bus: i2c) }
  let(:addr) { 0x44 }

  before { allow(provider).to receive(:sleep) }

  describe '#read_measurements' do
    it 'returns temperature and humidity from raw data' do
      # ST=0x6666=26214 => -45 + 175*(26214/65535) = 24.98°C
      # SRH=0x8000=32768 => 100*(32768/65535) = 50.00%
      allow(i2c).to receive(:read).with(addr, 6).and_return([0x66, 0x66, 0x00, 0x80, 0x00, 0x00])
      result = provider.read_measurements(addr)

      expect(result[:temperature_c]).to be_within(0.5).of(25.0)
      expect(result[:humidity]).to be_within(1.0).of(50.0)
    end

    it 'clamps humidity to 0-100 range' do
      # SRH=0xFFFF => 100.0% exactly
      allow(i2c).to receive(:read).with(addr, 6).and_return([0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00])
      result = provider.read_measurements(addr)

      expect(result[:humidity]).to be <= 100.0
    end

    it 'handles minimum temperature reading' do
      # ST=0x0000 => -45 + 0 = -45°C
      allow(i2c).to receive(:read).with(addr, 6).and_return([0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
      result = provider.read_measurements(addr)

      expect(result[:temperature_c]).to be_within(0.1).of(-45.0)
      expect(result[:humidity]).to be_within(0.1).of(0.0)
    end

    it 'handles maximum temperature reading' do
      # ST=0xFFFF => -45 + 175 = 130°C
      allow(i2c).to receive(:read).with(addr, 6).and_return([0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00])
      result = provider.read_measurements(addr)

      expect(result[:temperature_c]).to be_within(0.1).of(130.0)
    end
  end
end
