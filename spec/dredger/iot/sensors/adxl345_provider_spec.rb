# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::ADXL345Provider do
  let(:i2c) { Dredger::IoT::Bus::I2C.new }
  let(:addr) { 0x53 }

  before { allow_any_instance_of(described_class).to receive(:sleep) } # rubocop:disable RSpec/AnyInstance

  describe '#read_measurements' do
    it 'reads acceleration values in g units' do
      provider = described_class.new(i2c_bus: i2c, range: 2)

      # Device ID check
      allow(i2c).to receive(:read).with(addr, 1, register: 0x00).and_return([0xE5])
      # Acceleration data: x=256, y=-128, z=0 (little-endian signed 16-bit)
      allow(i2c).to receive(:read).with(addr, 6, register: 0x32).and_return([0x00, 0x01, 0x80, 0xFF, 0x00, 0x00])
      allow(i2c).to receive(:write)

      result = provider.read_measurements(addr)

      # range=2, scale=2/512=0.00390625
      expect(result[:x_g]).to be_within(0.001).of(256 * 2.0 / 512)
      expect(result[:y_g]).to be_within(0.001).of(-128 * 2.0 / 512)
      expect(result[:z_g]).to eq(0.0)
    end

    it 'raises when device ID does not match' do
      provider = described_class.new(i2c_bus: i2c)

      allow(i2c).to receive(:read).with(addr, 1, register: 0x00).and_return([0x00])

      expect { provider.read_measurements(addr) }.to raise_error(IOError, /ADXL345 not found/)
    end

    it 'uses correct scale factor for different ranges' do
      provider = described_class.new(i2c_bus: i2c, range: 16)

      allow(i2c).to receive(:read).with(addr, 1, register: 0x00).and_return([0xE5])
      # x=100 raw => 100 * (16/512) = 3.125g
      allow(i2c).to receive(:read).with(addr, 6, register: 0x32).and_return([0x64, 0x00, 0x00, 0x00, 0x00, 0x00])
      allow(i2c).to receive(:write)

      result = provider.read_measurements(addr)

      expect(result[:x_g]).to be_within(0.001).of(3.125)
    end

    it 'handles negative signed 16-bit values' do
      provider = described_class.new(i2c_bus: i2c, range: 2)

      allow(i2c).to receive(:read).with(addr, 1, register: 0x00).and_return([0xE5])
      # x=0xFFFF=-1, y=0x8000=-32768 (most negative)
      allow(i2c).to receive(:read).with(addr, 6, register: 0x32).and_return([0xFF, 0xFF, 0x00, 0x80, 0x00, 0x00])
      allow(i2c).to receive(:write)

      result = provider.read_measurements(addr)

      expect(result[:x_g]).to be_within(0.001).of(-1 * 2.0 / 512)
      expect(result[:y_g]).to be < 0
    end

    it 'rejects invalid range values' do
      expect { described_class.new(i2c_bus: i2c, range: 3) }
        .not_to raise_error # range validated at configure time, not init

      provider = described_class.new(i2c_bus: i2c, range: 3)
      allow(i2c).to receive(:read).with(addr, 1, register: 0x00).and_return([0xE5])
      allow(i2c).to receive(:read).with(addr, 6, register: 0x32).and_return([0x00] * 6)

      expect { provider.read_measurements(addr) }.to raise_error(ArgumentError, /Invalid range/)
    end
  end
end
