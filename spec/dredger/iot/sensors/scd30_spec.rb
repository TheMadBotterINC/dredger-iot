# frozen_string_literal: true

require 'spec_helper'

class FakeSCD30Provider
  def read_measurements(_addr)
    { co2_ppm: 412.5, temperature_c: 23.45, humidity: 45.2 }
  end
end

RSpec.describe Dredger::IoT::Sensors::SCD30 do
  it 'returns CO2, temperature, and humidity readings' do
    sensor = described_class.new(i2c_addr: 0x61, provider: FakeSCD30Provider.new)
    rs = sensor.readings
    expect(rs.size).to eq(3)
    
    co2 = rs.find { |r| r.sensor_type == 'co2' }
    temp = rs.find { |r| r.sensor_type == 'temperature' }
    hum = rs.find { |r| r.sensor_type == 'humidity' }
    
    expect(co2.unit).to eq('ppm')
    expect(temp.unit).to eq('celsius')
    expect(hum.unit).to eq('%')
    
    expect(co2.value).to eq(412.5)
    expect(temp.value).to eq(23.45)
    expect(hum.value).to eq(45.2)
  end

  it 'passes metadata to readings' do
    sensor = described_class.new(
      i2c_addr: 0x61,
      provider: FakeSCD30Provider.new,
      metadata: { location: 'greenhouse' }
    )
    rs = sensor.readings
    expect(rs.first.metadata[:location]).to eq('greenhouse')
  end

  it 'uses custom I2C address' do
    provider = FakeSCD30Provider.new
    expect(provider).to receive(:read_measurements).with(0x62).and_call_original
    sensor = described_class.new(i2c_addr: 0x62, provider: provider)
    sensor.readings
  end
end
