# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dredger::IoT::Pins::Beaglebone do
  it "validates labels and resolves PinRef" do
    expect(described_class.valid_label?("P9_12")).to be(true)
    pin = described_class.resolve("P9_12")
    expect(pin.to_s).to eq("P9_12")
    expect { described_class.resolve("P10_99") }.to raise_error(ArgumentError)
  end
end
