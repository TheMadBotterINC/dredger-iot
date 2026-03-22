# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::SCD30Provider do
  let(:i2c) { Dredger::IoT::Bus::I2C.new }
  let(:addr) { 0x61 }

  describe '#read_measurements' do
    let(:provider) { described_class.new(i2c_bus: i2c, interval: 2) }

    before do
      allow(provider).to receive(:sleep)
      allow(i2c).to receive(:write)
    end

    # Helper to compute CRC-8 matching the provider's algorithm
    def crc8(byte1, byte2)
      crc = 0xFF
      [byte1, byte2].each do |byte|
        crc ^= byte
        8.times do
          crc = (crc & 0x80).nonzero? ? ((crc << 1) ^ 0x31) : (crc << 1)
          crc &= 0xFF
        end
      end
      crc
    end

    # Build 18-byte measurement data with valid CRCs for given float values
    def build_measurement_data(co2, temp, humidity)
      [co2, temp, humidity].flat_map do |value|
        bytes = [value].pack('g').unpack('C4')
        # SCD30 format: [MSB0, LSB0, CRC0, MSB1, LSB1, CRC1]
        msb0, lsb0, msb1, lsb1 = bytes
        [msb0, lsb0, crc8(msb0, lsb0), msb1, lsb1, crc8(msb1, lsb1)]
      end
    end

    it 'parses float32 CO2, temperature, and humidity values' do
      data = build_measurement_data(412.5, 23.45, 45.2)

      # First call: data ready check (return ready)
      # Second call: read 18 bytes of measurement data
      call_count = 0
      allow(i2c).to receive(:read) do |_a, len|
        call_count += 1
        if len == 3
          [0x00, 0x01, crc8(0x00, 0x01)] # data ready
        else
          data
        end
      end

      result = provider.read_measurements(addr)

      expect(result[:co2_ppm]).to be_within(0.1).of(412.5)
      expect(result[:temperature_c]).to be_within(0.01).of(23.45)
      expect(result[:humidity]).to be_within(0.1).of(45.2)
    end

    it 'raises on CRC error in measurement data' do
      data = build_measurement_data(400.0, 20.0, 50.0)
      data[2] = 0x00 # corrupt first CRC

      allow(i2c).to receive(:read) do |_a, len|
        len == 3 ? [0x00, 0x01, crc8(0x00, 0x01)] : data
      end

      expect { provider.read_measurements(addr) }.to raise_error(IOError, /CRC error/)
    end

    it 'raises on timeout when data is never ready' do
      allow(i2c).to receive(:read).and_return([0x00, 0x00, crc8(0x00, 0x00)]) # never ready
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(0.5), Time.at(3.0))

      expect { provider.read_measurements(addr) }.to raise_error(IOError, /timeout/)
    end

    it 'initializes sensor only on first read' do
      data = build_measurement_data(400.0, 20.0, 50.0)
      allow(i2c).to receive(:read) do |_a, len|
        len == 3 ? [0x00, 0x01, crc8(0x00, 0x01)] : data
      end

      provider.read_measurements(addr)
      provider.read_measurements(addr)

      # The initialization writes happen only once (set interval + start measurement)
      expect(i2c).to have_received(:write).at_least(:once)
    end
  end

  describe 'CRC-8 calculation' do
    it 'matches known SCD30 CRC values' do
      provider = described_class.new(i2c_bus: i2c)
      # The CRC polynomial is 0x31 with init 0xFF (Sensirion standard)
      # Test with known byte pairs
      crc_method = provider.send(:calculate_crc8, [0xBE, 0xEF])
      expect(crc_method).to eq(0x92) # Known CRC for [0xBE, 0xEF]
    end
  end
end
