# frozen_string_literal: true

require 'spec_helper'

class FakeTSL2561Provider
  def read_lux(_addr)
    123.4
  end
end

RSpec.describe Dredger::IoT::Sensors::TSL2561 do
  it 'returns illuminance in lux' do
    sensor = described_class.new(i2c_addr: 0x39, provider: FakeTSL2561Provider.new)
    rs = sensor.readings
    expect(rs.size).to eq(1)
    r = rs.first
    expect(r.sensor_type).to eq('illuminance')
    expect(r.unit).to eq('lux')
    expect(r.value).to eq(123.4)
  end
end