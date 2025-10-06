# frozen_string_literal: true

require 'spec_helper'

class FakeNEO6MProvider
  def read_position(_device)
    {
      latitude: 37.774929,
      longitude: -122.419418,
      altitude: 52.4,
      speed: 12.5,
      satellites: 8,
      fix_quality: 1
    }
  end
end

RSpec.describe Dredger::IoT::Sensors::NEO6M do
  it 'returns GPS position readings with latitude, longitude, altitude, speed, and quality' do
    sensor = described_class.new(device: '/dev/ttyAMA0', provider: FakeNEO6MProvider.new)
    rs = sensor.readings
    expect(rs.size).to eq(5)
    
    lat = rs.find { |r| r.sensor_type == 'latitude' }
    lon = rs.find { |r| r.sensor_type == 'longitude' }
    alt = rs.find { |r| r.sensor_type == 'altitude' }
    speed = rs.find { |r| r.sensor_type == 'speed' }
    quality = rs.find { |r| r.sensor_type == 'gps_quality' }
    
    expect(lat.unit).to eq('degrees')
    expect(lon.unit).to eq('degrees')
    expect(alt.unit).to eq('m')
    expect(speed.unit).to eq('km/h')
    expect(quality.unit).to eq('satellites')
    
    expect(lat.value).to eq(37.774929)
    expect(lon.value).to eq(-122.419418)
    expect(alt.value).to eq(52.4)
    expect(speed.value).to eq(12.5)
    expect(quality.value).to eq(8)
    expect(quality.metadata[:fix_quality]).to eq(1)
  end

  it 'passes metadata to readings' do
    sensor = described_class.new(
      device: '/dev/ttyAMA0',
      provider: FakeNEO6MProvider.new,
      metadata: { location: 'vehicle' }
    )
    rs = sensor.readings
    expect(rs.first.metadata[:location]).to eq('vehicle')
  end

  it 'uses custom serial device' do
    provider = FakeNEO6MProvider.new
    expect(provider).to receive(:read_position).with('/dev/ttyUSB0').and_call_original
    sensor = described_class.new(device: '/dev/ttyUSB0', provider: provider)
    sensor.readings
  end
end
