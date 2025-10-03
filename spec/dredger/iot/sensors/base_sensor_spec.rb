# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dredger::IoT::Sensors::BaseSensor do
  it 'raises NotImplementedError for readings' do
    sensor = described_class.new
    expect { sensor.readings }.to raise_error(NotImplementedError)
  end

  it 'builds a Reading with defaults via helper in subclass' do
    klass = Class.new(described_class) do
      def readings
        [reading(sensor_type: 'humidity', value: 50.0, unit: '%')]
      end
    end
    sensor = klass.new(metadata: { source: 'test' })
    r = sensor.readings.first
    expect(r.sensor_type).to eq('humidity')
    expect(r.unit).to eq('%')
    expect(r.metadata[:source]).to eq('test')
    expect(r.calibrated).to be(true)
  end
end
# EOF
