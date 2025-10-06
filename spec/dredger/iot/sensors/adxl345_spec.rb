# frozen_string_literal: true

require 'spec_helper'

class FakeADXL345Provider
  def read_measurements(_addr)
    { x_g: 0.024, y_g: -0.012, z_g: 0.980 }
  end
end

RSpec.describe Dredger::IoT::Sensors::ADXL345 do
  it 'returns acceleration readings for x, y, z axes in g units' do
    sensor = described_class.new(i2c_addr: 0x53, provider: FakeADXL345Provider.new)
    rs = sensor.readings
    expect(rs.size).to eq(3)
    
    x_accel = rs.find { |r| r.sensor_type == 'acceleration_x' }
    y_accel = rs.find { |r| r.sensor_type == 'acceleration_y' }
    z_accel = rs.find { |r| r.sensor_type == 'acceleration_z' }
    
    expect(x_accel.unit).to eq('g')
    expect(y_accel.unit).to eq('g')
    expect(z_accel.unit).to eq('g')
    
    expect(x_accel.value).to eq(0.024)
    expect(y_accel.value).to eq(-0.012)
    expect(z_accel.value).to eq(0.980)
  end

  it 'passes metadata to readings' do
    sensor = described_class.new(
      i2c_addr: 0x53,
      provider: FakeADXL345Provider.new,
      metadata: { location: 'motor_mount' }
    )
    rs = sensor.readings
    expect(rs.first.metadata[:location]).to eq('motor_mount')
  end

  it 'uses custom I2C address' do
    provider = FakeADXL345Provider.new
    expect(provider).to receive(:read_measurements).with(0x1D).and_call_original
    sensor = described_class.new(i2c_addr: 0x1D, provider: provider)
    sensor.readings
  end
end
