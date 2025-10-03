# frozen_string_literal: true

require "spec_helper"

class FakeBmeProvider
  def read_measurements(_addr)
    { temperature_c: 24.1, humidity: 40.2, pressure_kpa: 101.4 }
  end
end

RSpec.describe Dredger::IoT::Sensors::BME280 do
  it "returns temp, humidity, pressure readings with correct units" do
    sensor = described_class.new(i2c_addr: 0x76, provider: FakeBmeProvider.new)
    rs = sensor.readings
    expect(rs.map(&:sensor_type)).to contain_exactly("temperature", "humidity", "pressure")
    expect(rs.find { |r| r.sensor_type == "pressure" }.unit).to eq("kPa")
  end
end