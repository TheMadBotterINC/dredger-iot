# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::DHT22Provider do
  let(:gpio_bus) { Dredger::IoT::Bus::GPIO.new }

  it 'samples DHT22 and returns humidity and temperature' do
    provider = described_class.new(gpio_bus: gpio_bus)
    # NOTE: Since bit-banging is stubbed, this returns fixed data
    result = nil
    expect { result = provider.sample('P9_12') }.to output(/bit-banging not fully implemented/).to_stderr
    expect(result[:humidity]).to be_within(0.1).of(65.2)
    expect(result[:temperature_c]).to be_within(0.1).of(31.4)
  end

  it 'raises on checksum mismatch' do
    provider = described_class.new(gpio_bus: gpio_bus)
    # Stub read_40_bits to return invalid checksum
    allow(provider).to receive(:read_40_bits).with(any_args).and_return([0x01, 0x00, 0x00, 0x00, 0xFF])
    expect { provider.sample('P9_12') }.to raise_error(IOError, /checksum mismatch/)
  end

  it 'handles negative temperatures' do
    provider = described_class.new(gpio_bus: gpio_bus)
    # Stub data: temp MSB set (negative), checksum valid
    # temp_raw = 0x8064 => -(0x0064) = -100 => -10.0°C
    allow(provider).to receive(:read_40_bits).with(any_args).and_return([0x02, 0x00, 0x80, 0x64, 0xE6])
    result = nil
    expect { result = provider.sample('P9_12') }.not_to raise_error
    expect(result[:temperature_c]).to eq(-10.0)
  end
end
# EOF
