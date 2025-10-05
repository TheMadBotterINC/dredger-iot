# frozen_string_literal: true

require 'spec_helper'

class FakeBH1750Provider
  def read_lux(_addr)
    456.7
  end
end

RSpec.describe Dredger::IoT::Sensors::BH1750 do
  it 'returns illuminance reading in lux' do
    sensor = described_class.new(i2c_addr: 0x23, provider: FakeBH1750Provider.new)
    rs = sensor.readings
    expect(rs.size).to eq(1)
    r = rs.first
    expect(r.sensor_type).to eq('illuminance')
    expect(r.unit).to eq('lux')
    expect(r.value).to eq(456.7)
  end
end