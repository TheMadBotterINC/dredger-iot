# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Bus::I2C do
  it 'reads and writes using the simulation backend' do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    bus.write(0x76, [0xAA, 0xBB, 0xCC], register: 0x10)
    expect(bus.read(0x76, 3, register: 0x10)).to eq([0xAA, 0xBB, 0xCC])
  end

  it 'responds to close without error' do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    expect { bus.close }.not_to raise_error
  end

  it 'delegates close to backend when backend supports it' do
    backend = instance_double('Backend', close: nil)
    allow(backend).to receive(:respond_to?).and_return(false)
    allow(backend).to receive(:respond_to?).with(:close).and_return(true)
    bus = described_class.new(backend: backend)

    bus.close
    expect(backend).to have_received(:close)
  end

  it 'supports sequential write without register and seed helper' do
    sim = described_class::Simulation.new
    bus = described_class.new(backend: sim)

    bus.write(0x20, [0x01, 0x02])
    expect(bus.read(0x20, 2)).to eq([0x01, 0x02])

    sim.seed(0x21, 0x05, [0x0A, 0x0B])
    expect(bus.read(0x21, 2, register: 0x05)).to eq([0x0A, 0x0B])

    expect { bus.read(0x22, 0) }.to raise_error(ArgumentError)
  end
end
