# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Pins::Beaglebone do
  it 'validates labels and resolves PinRef' do
    expect(described_class.valid_label?('P9_12')).to be(true)
    pin = described_class.resolve('P9_12')
    expect(pin.to_s).to eq('P9_12')
    expect { described_class.resolve('P10_99') }.to raise_error(ArgumentError)
  end

  it 'formats PinRef with chip:line when present' do
    pref = described_class::PinRef.new(label: 'P9_12', chip: 0, line: 1)
    expect(pref.to_s).to eq('P9_12(chip0:1)')
  end

  it 'resolves known labels to chip:line via mapping' do
    pinref = described_class.resolve_label_to_pinref('P9_12')
    expect(pinref.chip).to eq(1)
    expect(pinref.line).to eq(28)
  end
end
