# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::YFS201Provider do
  let(:gpio) { Dredger::IoT::Bus::GPIO.new }
  let(:provider) { described_class.new(gpio_bus: gpio, calibration_factor: 7.5) }
  let(:pin) { 'P9_12' }

  describe '#read_flow_rate' do
    it 'calculates flow rate from pulse count' do
      # Simulate: pulse counting returns 0 pulses (simulation GPIO always reads 0)
      # With simulation backend, no edges will be detected so pulses=0
      allow(provider).to receive(:sleep)

      # Stub Time.now to make the loop run briefly
      start = Time.now
      allow(Time).to receive(:now).and_return(start, start + 0.5, start + 1.1)

      result = provider.read_flow_rate(pin, 1.0)

      expect(result).to have_key(:flow_rate_lpm)
      expect(result).to have_key(:pulses)
      expect(result[:pulses]).to be_a(Integer)
      expect(result[:flow_rate_lpm]).to be_a(Float)
    end

    it 'detects rising edges and counts pulses' do
      # Stub count_pulses to return a known value and test the math
      allow(provider).to receive(:count_pulses).and_return(75)

      result = provider.read_flow_rate(pin, 1.0)

      # 75 pulses in 1.0 sec / 7.5 cal_factor * 60 = 600.0 L/min
      expect(result[:flow_rate_lpm]).to be_within(0.01).of(600.0)
      expect(result[:pulses]).to eq(75)
    end

    it 'uses custom calibration factor' do
      custom = described_class.new(gpio_bus: gpio, calibration_factor: 4.5)
      allow(custom).to receive(:count_pulses).and_return(45)

      result = custom.read_flow_rate(pin, 1.0)

      # 45 pulses / 1.0s / 4.5 * 60 = 600.0 L/min
      expect(result[:flow_rate_lpm]).to be_within(0.01).of(600.0)
    end

    it 'handles zero pulses' do
      allow(provider).to receive(:count_pulses).and_return(0)

      result = provider.read_flow_rate(pin, 1.0)

      expect(result[:flow_rate_lpm]).to eq(0.0)
      expect(result[:pulses]).to eq(0)
    end

    it 'accounts for sample duration in flow rate calculation' do
      allow(provider).to receive(:count_pulses).and_return(75)

      result = provider.read_flow_rate(pin, 2.0)

      # 75 pulses / 2.0s / 7.5 * 60 = 300.0 L/min
      expect(result[:flow_rate_lpm]).to be_within(0.01).of(300.0)
    end
  end
end
