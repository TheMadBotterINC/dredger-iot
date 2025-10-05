# frozen_string_literal: true

require 'spec_helper'

class FakeINA219Provider
  def read_measurements(_addr)
    { bus_voltage_v: 12.08, current_ma: 152.3, shunt_voltage_mv: 15.23 }
  end
end

RSpec.describe Dredger::IoT::Sensors::INA219 do
  it 'returns bus voltage in V and current in mA' do
    sensor = described_class.new(i2c_addr: 0x40, provider: FakeINA219Provider.new)
    rs = sensor.readings
    expect(rs.map(&:sensor_type)).to contain_exactly('bus_voltage', 'current')
    bus = rs.find { |r| r.sensor_type == 'bus_voltage' }
    cur = rs.find { |r| r.sensor_type == 'current' }
    expect(bus.unit).to eq('V')
    expect(cur.unit).to eq('mA')
    expect(bus.value).to eq(12.08)
    expect(cur.value).to eq(152.3)
  end
end
