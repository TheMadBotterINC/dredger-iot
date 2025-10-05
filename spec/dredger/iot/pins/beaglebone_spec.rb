# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Pins::Beaglebone do
  it 'validates labels and resolves PinRef' do
    expect(described_class.valid_label?('P9_12')).to be(true)
    pin = described_class.resolve('P9_12')
    expect(pin.to_s).to eq('P9_12')
  end

  it 'formats PinRef with chip:line when present' do
    pref = described_class::PinRef.new(label: 'P9_12', chip: 0, line: 1)
    expect(pref.to_s).to eq('P9_12(chip0:1)')
  end

  it 'resolves mapped chip:line and raises on missing or unknown mapping' do
    chip, line = described_class.chip_line_for('P9_12')
    expect(chip).to eq('gpiochip1')
    expect(line).to eq(28)

    expect { described_class.chip_line_for('P9_13') }.to raise_error(ArgumentError)
    expect { described_class.resolve('P10_99') }.to raise_error(ArgumentError)
    expect { described_class.chip_line_for('P10_99') }.to raise_error(ArgumentError)
  end

  describe Dredger::IoT::Bus::GPIOLabelAdapter do
    it 'resolves Beaglebone labels with mapping' do
      backend = Class.new do
        attr_reader :resolved

        def set_direction(pin, _dir)
          @resolved = pin
        end
      end.new

      adapter = described_class.new(backend: backend)
      adapter.set_direction('P9_12', :out)
      expect(backend.resolved.chip).to eq(1)
      expect(backend.resolved.line).to eq(28)
    end
  end
end
