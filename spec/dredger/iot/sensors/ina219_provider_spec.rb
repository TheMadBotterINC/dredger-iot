# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::INA219Provider do
  let(:i2c) { Dredger::IoT::Bus::I2C.new }
  let(:addr) { 0x40 }

  describe '#read_measurements' do
    it 'computes bus voltage, current, and shunt voltage from raw data' do
      provider = described_class.new(i2c_bus: i2c, shunt_resistance_ohms: 0.1)

      # Shunt register (0x01): raw=1000 => 10.0 mV
      # Bus register (0x02): raw=0x3200 => (0x3200>>3)*0.004 = 1600*0.004 = 6.4V
      allow(i2c).to receive(:read).with(addr, 2, register: 0x01).and_return([0x03, 0xE8])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x02).and_return([0x32, 0x00])

      result = provider.read_measurements(addr)

      expect(result[:shunt_voltage_mv]).to be_within(0.01).of(10.0)
      expect(result[:current_ma]).to be_within(0.01).of(100.0)
      expect(result[:bus_voltage_v]).to be_within(0.01).of(6.4)
    end

    it 'handles negative shunt voltage (signed 16-bit)' do
      provider = described_class.new(i2c_bus: i2c, shunt_resistance_ohms: 0.1)

      # raw=0xFC18 => signed: 0xFC18 - 0x10000 = -1000 => -10.0 mV
      allow(i2c).to receive(:read).with(addr, 2, register: 0x01).and_return([0xFC, 0x18])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x02).and_return([0x00, 0x00])

      result = provider.read_measurements(addr)

      expect(result[:shunt_voltage_mv]).to be_within(0.01).of(-10.0)
      expect(result[:current_ma]).to be_within(0.01).of(-100.0)
    end

    it 'returns zero current when shunt resistance is zero' do
      provider = described_class.new(i2c_bus: i2c, shunt_resistance_ohms: 0.0)

      allow(i2c).to receive(:read).with(addr, 2, register: 0x01).and_return([0x03, 0xE8])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x02).and_return([0x00, 0x00])

      result = provider.read_measurements(addr)

      expect(result[:current_ma]).to eq(0.0)
    end

    it 'uses custom shunt resistance' do
      provider = described_class.new(i2c_bus: i2c, shunt_resistance_ohms: 0.05)

      # 10.0 mV / 0.05 ohm = 200.0 mA
      allow(i2c).to receive(:read).with(addr, 2, register: 0x01).and_return([0x03, 0xE8])
      allow(i2c).to receive(:read).with(addr, 2, register: 0x02).and_return([0x00, 0x00])

      result = provider.read_measurements(addr)

      expect(result[:current_ma]).to be_within(0.01).of(200.0)
    end
  end
end
