# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dredger::IoT::Bus::GPIO do
  it "supports simulation backend read/write" do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    sim.inject_input("P9_12", 1)
    expect(bus.read("P9_12")).to eq(1)

    bus.set_direction("P9_14", :out)
    bus.write("P9_14", 1)
    expect(bus.read("P9_14")).to eq(1)
  end

  it "validates directions and values" do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    expect { bus.set_direction("P9_12", :bad) }.to raise_error(ArgumentError)
    bus.set_direction("P9_12", :out)
    expect { bus.write("P9_12", 2) }.to raise_error(ArgumentError)
  end
end