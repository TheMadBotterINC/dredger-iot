# frozen_string_literal: true

require "spec_helper"

class FakeDhtProvider
  def sample(_pin)
    { humidity: 65.5, temperature_c: 22.3 }
  end
end

RSpec.describe Dredger::IoT::Sensors::DHT22 do
  it "returns humidity and temperature readings with correct units" do
    sensor = described_class.new(pin_label: "P9_12", provider: FakeDhtProvider.new)
    rs = sensor.readings
    expect(rs.size).to eq(2)
    hum = rs.find { |r| r.sensor_type == "humidity" }
    temp = rs.find { |r| r.sensor_type == "temperature" }
    expect(hum.unit).to eq("%")
    expect(temp.unit).to eq("celsius")
  end
end
