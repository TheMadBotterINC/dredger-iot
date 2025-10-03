# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::BME280Provider do
  let(:i2c_bus) { Dredger::IoT::Bus::I2C.new }
  let(:addr) { 0x76 }

  it 'reads measurements from BME280 sensor' do
    provider = described_class.new(i2c_bus: i2c_bus)

    # Stub I2C reads for chip_id, calibration, and measurement data
    allow(i2c_bus).to receive(:read).with(addr, 1, register: 0xD0).and_return([0x60]) # chip_id
    allow(i2c_bus).to receive(:read).with(addr, 26, register: 0x88).and_return(stub_calib1)
    allow(i2c_bus).to receive(:read).with(addr, 7, register: 0xE1).and_return(stub_calib2)
    allow(i2c_bus).to receive(:read).with(addr, 8, register: 0xF7).and_return(stub_measurement_data)
    allow(i2c_bus).to receive(:write)

    result = provider.read_measurements(addr)
    expect(result[:temperature_c]).to be_a(Float)
    expect(result[:humidity]).to be_a(Float)
    expect(result[:pressure_kpa]).to be_a(Float)
    expect(result[:humidity]).to be >= 0.0
    expect(result[:humidity]).to be <= 100.0
  end

  it 'raises when chip_id does not match' do
    provider = described_class.new(i2c_bus: i2c_bus)
    allow(i2c_bus).to receive(:read).with(addr, 1, register: 0xD0).and_return([0x58]) # wrong chip_id

    expect { provider.read_measurements(addr) }.to raise_error(IOError, /not found/)
  end

  it 'clamps humidity to 0-100 range' do
    provider = described_class.new(i2c_bus: i2c_bus)
    # Test the compensate_humidity edge cases by stubbing internal state
    provider.instance_variable_set(:@t_fine, 128_000)
    calib = { dig_h1: 75, dig_h2: 358, dig_h3: 0, dig_h4: 321, dig_h5: 50, dig_h6: 30 }

    # Very low humidity raw value
    result = provider.send(:compensate_humidity, 10_000, calib, 25.0)
    expect(result).to be >= 0.0

    # Very high humidity raw value
    result = provider.send(:compensate_humidity, 50_000, calib, 25.0)
    expect(result).to be <= 100.0
  end

  # Helper: stub calibration data (simplified for testing)
  def stub_calib1
    [
      0x88, 0x6D, # dig_t1 = 28040 (bytes 0-1)
      0x67, 0x01, # dig_t2 = 359 (bytes 2-3)
      0x00, 0x00, # dig_t3 = 0 (bytes 4-5)
      0x7E, 0x8F, # dig_p1 = 36734 (bytes 6-7)
      0xD6, 0xD0, # dig_p2 = -12074 (bytes 8-9)
      0xD0, 0x0B, # dig_p3 = 3024 (bytes 10-11)
      0x27, 0x0D, # dig_p4 = 3367 (bytes 12-13)
      0x8D, 0xFF, # dig_p5 = -115 (bytes 14-15)
      0xF9, 0xFF, # dig_p6 = -7 (bytes 16-17)
      0x9D, 0x00, # dig_p7 = 157 (bytes 18-19)
      0x00, 0x00, # dig_p8 = 0 (bytes 20-21)
      0x80, 0x00, # dig_p9 = 128 (bytes 22-23)
      0x00,       # unused (byte 24)
      0x4B        # dig_h1 = 75 (byte 25)
    ]
  end

  def stub_calib2
    [
      0x66, 0x01, # dig_h2 = 358
      0x00,       # dig_h3 = 0
      0x11, 0x41, # dig_h4/h5 encoded
      0x32,       # dig_h5 cont
      0x1E        # dig_h6 = 30
    ]
  end

  # Stub measurement data: reasonable raw ADC values
  def stub_measurement_data
    [
      0x50, 0x00, 0x00, # pressure_raw ~ 327680
      0x80, 0x00, 0x00, # temp_raw ~ 524288
      0x80, 0x00        # hum_raw ~ 32768
    ]
  end
end
# EOF
