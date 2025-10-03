# frozen_string_literal: true

require 'spec_helper'
require 'dredger/iot/bus/gpio_label_adapter'

class DummyLibgpiodBackend
  attr_reader :last_pin, :last_op, :last_value

  def set_direction(pin, direction)
    @last_pin = pin
    @last_op = [:set_direction, direction]
  end

  def write(pin, value)
    @last_pin = pin
    @last_value = value
    @last_op = [:write]
  end

  def read(pin)
    @last_pin = pin
    @last_op = [:read]
    1
  end
end

RSpec.describe Dredger::IoT::Bus::GPIOLabelAdapter do
  it 'translates P9_12 to chip1:28 PinRef for write' do
    backend = DummyLibgpiodBackend.new
    adapter = described_class.new(backend: backend)
    adapter.write('P9_12', 1)
    pin = backend.last_pin
    expect(pin.label).to eq('P9_12')
    expect(pin.chip).to eq(1)
    expect(pin.line).to eq(28)
    expect(backend.last_value).to eq(1)
  end

  it 'passes through integer line values' do
    backend = DummyLibgpiodBackend.new
    adapter = described_class.new(backend: backend)
    adapter.write(7, 1)
    expect(backend.last_pin).to eq(7)
  end

  it 'passes through PinRef with line' do
    backend = DummyLibgpiodBackend.new
    adapter = described_class.new(backend: backend)
    pref = Dredger::IoT::Pins::Beaglebone::PinRef.new(label: 'P9_12', chip: 1, line: 28)
    adapter.write(pref, 1)
    expect(backend.last_pin).to eq(pref)
  end

  it 'raises for unknown label format' do
    backend = DummyLibgpiodBackend.new
    adapter = described_class.new(backend: backend)
    expect { adapter.write('UNKNOWN', 1) }.to raise_error(ArgumentError)
  end

  it 'delegates set_direction to backend with resolved pin' do
    backend = DummyLibgpiodBackend.new
    adapter = described_class.new(backend: backend)
    adapter.set_direction('P9_12', :out)
    expect(backend.last_op).to eq(%i[set_direction out])
    expect(backend.last_pin.chip).to eq(1)
    expect(backend.last_pin.line).to eq(28)
  end

  it 'delegates read to backend with resolved pin' do
    backend = DummyLibgpiodBackend.new
    adapter = described_class.new(backend: backend)
    val = adapter.read('P9_12')
    expect(val).to eq(1)
    expect(backend.last_op).to eq([:read])
  end

  it 'raises Unsupported pin format when mapper cannot resolve' do
    backend = DummyLibgpiodBackend.new
    mapper = Module.new # does not respond to :resolve_label_to_pinref
    adapter = described_class.new(backend: backend, mapper: mapper)
    expect { adapter.write('X1_1', 1) }.to raise_error(ArgumentError, 'Unsupported pin format')
  end
end
# EOF
