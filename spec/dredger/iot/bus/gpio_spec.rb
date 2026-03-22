# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Bus::GPIO do
  it 'supports simulation backend read/write' do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    sim.inject_input('P9_12', 1)
    expect(bus.read('P9_12')).to eq(1)

    # Default for uninitialized pins is 0
    expect(bus.read('P8_01')).to eq(0)

    bus.set_direction('P9_14', :out)
    bus.write('P9_14', 1)
    expect(bus.read('P9_14')).to eq(1)
  end

  it 'responds to close without error' do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    expect { bus.close }.not_to raise_error
  end

  it 'delegates close to backend when backend supports it' do
    close_called = false
    sim = described_class::Simulation.new
    sim.define_singleton_method(:close) { close_called = true }
    bus = described_class.new(backend: sim)

    bus.close
    expect(close_called).to be(true)
  end

  it 'validates directions and values' do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    expect { bus.set_direction('P9_12', :bad) }.to raise_error(ArgumentError)
    bus.set_direction('P9_12', :in)
    expect { bus.write('P9_12', 1) }.to raise_error(RuntimeError)

    bus.set_direction('P9_14', :out)
    expect { bus.write('P9_14', 2) }.to raise_error(ArgumentError)
  end
end
