# frozen_string_literal: true

require 'spec_helper'

class FakeSHT31Provider
  def read_measurements(_addr)
    { temperature_c: 21.5, humidity: 55.2 }
  end
end

RSpec.describe Dredger::IoT::Sensors::SHT31 do
  it 'returns temperature and humidity with correct units' do
    sensor = described_class.new(i2c_addr: 0x44, provider: FakeSHT31Provider.new)
    rs = sensor.readings
    expect(rs.map(&:sensor_type)).to contain_exactly('temperature', 'humidity')
    temp = rs.find { |r| r.sensor_type == 'temperature' }
    hum = rs.find { |r| r.sensor_type == 'humidity' }
    expect(temp.unit).to eq('celsius')
    expect(hum.unit).to eq('%')
    expect(temp.value).to eq(21.5)
    expect(hum.value).to eq(55.2)
  end
end