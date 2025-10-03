# frozen_string_literal: true

require 'spec_helper'

class FakeBMP180Provider
  def read_measurements(_addr)
    { temperature_c: 25.3, pressure_pa: 101_325 }
  end
end

RSpec.describe Dredger::IoT::Sensors::BMP180 do
  it 'returns temperature and pressure readings with correct units' do
    sensor = described_class.new(i2c_addr: 0x77, provider: FakeBMP180Provider.new)
    rs = sensor.readings
    expect(rs.map(&:sensor_type)).to contain_exactly('temperature', 'pressure')
    press = rs.find { |r| r.sensor_type == 'pressure' }
    expect(press.unit).to eq('kPa')
    expect(press.value).to be_within(0.1).of(101.3)
  end
end
# EOF
