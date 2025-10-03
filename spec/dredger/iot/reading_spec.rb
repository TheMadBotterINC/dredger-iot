# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dredger::IoT::Reading do
  it "freezes instances and exposes a hash" do
    t = Time.utc(2025, 10, 3)
    r = described_class.new(sensor_type: "humidity", value: 55.0, unit: "%", recorded_at: t, calibrated: true, accuracy: 0.5, metadata: { foo: "bar" })
    expect(r.frozen?).to be(true)
    expect(r.to_h).to include(sensor_type: "humidity", value: 55.0, unit: "%", recorded_at: t, calibrated: true)
  end
end