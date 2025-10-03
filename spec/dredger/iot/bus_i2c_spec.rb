# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dredger::IoT::Bus::I2C do
  it "reads and writes using the simulation backend" do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    bus.write(0x76, [0xAA, 0xBB, 0xCC], register: 0x10)
    expect(bus.read(0x76, 3, register: 0x10)).to eq([0xAA, 0xBB, 0xCC])
  end
end