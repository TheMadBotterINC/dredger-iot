# frozen_string_literal: true

require 'spec_helper'

class FakeYFS201Provider
  def read_flow_rate(_pin, _duration)
    { flow_rate_lpm: 5.25, pulses: 656 }
  end
end

RSpec.describe Dredger::IoT::Sensors::YFS201 do
  it 'returns flow rate in L/min with pulse count metadata' do
    sensor = described_class.new(
      pin_label: 'P9_12',
      provider: FakeYFS201Provider.new,
      sample_duration: 1.0
    )
    rs = sensor.readings
    expect(rs.size).to eq(1)
    
    flow = rs.first
    expect(flow.sensor_type).to eq('flow_rate')
    expect(flow.unit).to eq('L/min')
    expect(flow.value).to eq(5.25)
    expect(flow.metadata[:pulses]).to eq(656)
    expect(flow.metadata[:duration]).to eq(1.0)
  end

  it 'passes metadata to readings' do
    sensor = described_class.new(
      pin_label: 'P9_12',
      provider: FakeYFS201Provider.new,
      metadata: { location: 'main_line' }
    )
    rs = sensor.readings
    expect(rs.first.metadata[:location]).to eq('main_line')
  end

  it 'uses custom sample duration' do
    provider = FakeYFS201Provider.new
    expect(provider).to receive(:read_flow_rate).with('GPIO17', 2.0).and_call_original
    sensor = described_class.new(
      pin_label: 'GPIO17',
      provider: provider,
      sample_duration: 2.0
    )
    sensor.readings
  end

  it 'passes pin label to provider' do
    provider = FakeYFS201Provider.new
    expect(provider).to receive(:read_flow_rate).with('P8_11', anything).and_call_original
    sensor = described_class.new(pin_label: 'P8_11', provider: provider)
    sensor.readings
  end
end
