# frozen_string_literal: true

require 'spec_helper'

class FakeMCP9808Provider
  def read_temperature(_addr)
    23.75
  end
end

RSpec.describe Dredger::IoT::Sensors::MCP9808 do
  it 'returns temperature reading with correct unit' do
    sensor = described_class.new(i2c_addr: 0x18, provider: FakeMCP9808Provider.new)
    rs = sensor.readings
    expect(rs.size).to eq(1)
    temp = rs.first
    expect(temp.sensor_type).to eq('temperature')
    expect(temp.unit).to eq('celsius')
    expect(temp.value).to eq(23.75)
  end
end
# EOF
