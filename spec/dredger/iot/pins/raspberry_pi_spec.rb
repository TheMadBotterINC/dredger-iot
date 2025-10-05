# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Pins::RaspberryPi do
  it 'resolves GPIO/BCM labels to chip0 and correct line' do
    pr = described_class.resolve_label_to_pinref('GPIO17')
    expect(pr.chip).to eq(0)
    expect(pr.line).to eq(17)

    pr2 = described_class.resolve_label_to_pinref('BCM22')
    expect(pr2.chip).to eq(0)
    expect(pr2.line).to eq(22)
  end

  it 'resolves PIN/BOARD labels using header mapping' do
    pr = described_class.resolve_label_to_pinref('PIN11') # -> BCM17
    expect(pr.chip).to eq(0)
    expect(pr.line).to eq(17)
    # cover to_s with chip/line present
    expect(pr.to_s).to include('chip0:17')
  end

  it 'is considered valid for label formats it supports' do
    expect(described_class.valid_label?('GPIO17')).to be(true)
    expect(described_class.valid_label?('BOARD11')).to be(true)
    expect(described_class.valid_label?('P9_12')).to be(false)
  end

  it 'raises on unsupported board pin and unknown label' do
    expect { described_class.resolve_label_to_pinref('PIN1') }.to raise_error(ArgumentError)
    expect { described_class.resolve_label_to_pinref('FOO') }.to raise_error(ArgumentError)
  end

  it 'passes through PinRef and Integer pins unchanged' do
    backend = Class.new do
      attr_reader :got

      def set_direction(pin, _dir)
        @got = pin
      end
    end.new

    adapter = Dredger::IoT::Bus::GPIOLabelAdapter.new(backend: backend)

    # PinRef pass-through
    pinref = described_class.resolve_label_to_pinref('GPIO17')
    adapter.set_direction(pinref, :out)
    expect(backend.got).to equal(pinref)

    # Integer pass-through
    adapter.set_direction(17, :out)
    expect(backend.got).to eq(17)
  end

  context 'with GPIOLabelAdapter' do
    it 'uses RaspberryPi mapper when provided with GPIO label' do
      backend = Class.new do
        attr_reader :resolved, :written

        def set_direction(pin, _dir)
          @resolved = pin
        end

        def write(pin, value)
          @resolved = pin
          @written = value
        end

        def read(pin)
          @resolved = pin
          1
        end
      end.new

      adapter = Dredger::IoT::Bus::GPIOLabelAdapter.new(backend: backend)
      adapter.set_direction('GPIO17', :out)
      expect(backend.resolved.line).to eq(17)
      # also exercise write and read paths
      adapter.write('GPIO17', 1)
      expect(backend.written).to eq(1)
      expect(adapter.read('GPIO17')).to eq(1)
    end
  end
end
