# frozen_string_literal: true

require 'spec_helper'

class FakeDS18B20Provider
  def read_temperature(_device_id)
    22.5
  end
end

RSpec.describe Dredger::IoT::Sensors::DS18B20 do
  it 'returns temperature reading with correct unit' do
    sensor = described_class.new(device_id: '28-0000056789ab', provider: FakeDS18B20Provider.new)
    rs = sensor.readings
    expect(rs.size).to eq(1)
    temp = rs.first
    expect(temp.sensor_type).to eq('temperature')
    expect(temp.unit).to eq('celsius')
    expect(temp.value).to eq(22.5)
  end
end
# EOF
