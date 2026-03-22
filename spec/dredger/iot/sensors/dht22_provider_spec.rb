# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::DHT22Provider do
  let(:gpio_bus) { Dredger::IoT::Bus::GPIO.new }

  it 'raises NotImplementedError for bit-banging read' do
    provider = described_class.new(gpio_bus: gpio_bus)
    expect { provider.sample('P9_12') }.to raise_error(NotImplementedError, /bit-banging requires/)
  end

  it 'parses valid 40-bit data when read_40_bits is provided' do
    provider = described_class.new(gpio_bus: gpio_bus)
    # humidity=65.2% => 0x028C, temp=31.4°C => 0x013A, checksum=0xC9
    allow(provider).to receive(:read_40_bits).with(any_args).and_return([0x02, 0x8C, 0x01, 0x3A, 0xC9])
    result = provider.sample('P9_12')
    expect(result[:humidity]).to be_within(0.1).of(65.2)
    expect(result[:temperature_c]).to be_within(0.1).of(31.4)
  end

  it 'raises on checksum mismatch' do
    provider = described_class.new(gpio_bus: gpio_bus)
    allow(provider).to receive(:read_40_bits).with(any_args).and_return([0x01, 0x00, 0x00, 0x00, 0xFF])
    expect { provider.sample('P9_12') }.to raise_error(IOError, /checksum mismatch/)
  end

  it 'handles negative temperatures' do
    provider = described_class.new(gpio_bus: gpio_bus)
    # temp_raw = 0x8064 => -(0x0064) = -100 => -10.0°C
    allow(provider).to receive(:read_40_bits).with(any_args).and_return([0x02, 0x00, 0x80, 0x64, 0xE6])
    result = provider.sample('P9_12')
    expect(result[:temperature_c]).to eq(-10.0)
  end
end
