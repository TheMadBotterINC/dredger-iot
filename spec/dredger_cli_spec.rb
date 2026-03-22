# frozen_string_literal: true

require 'spec_helper'
require 'json'

# Load the CLI class
load File.expand_path('../bin/dredger', __dir__)

RSpec.describe DredgerCLI do
  let(:cli) { described_class.new }

  describe '#output_readings' do
    let(:recorded_time) { Time.utc(2025, 10, 3, 12, 0, 0) }

    let(:readings) do
      [
        Dredger::IoT::Reading.new(
          sensor_type: 'temperature', value: 24.1, unit: 'celsius',
          recorded_at: recorded_time, calibrated: true, metadata: {}
        ),
        Dredger::IoT::Reading.new(
          sensor_type: 'humidity', value: 40.2, unit: '%',
          recorded_at: recorded_time, calibrated: true, metadata: {}
        )
      ]
    end

    context 'with json format' do
      before do
        cli.instance_variable_set(:@options, { format: 'json', backend: 'simulation' })
      end

      it 'outputs valid JSON with correct timestamps from recorded_at' do
        output = capture_stdout { cli.send(:output_readings, readings) }
        data = JSON.parse(output)

        expect(data).to be_an(Array)
        expect(data.length).to eq(2)

        expect(data[0]['sensor_type']).to eq('temperature')
        expect(data[0]['value']).to eq(24.1)
        expect(data[0]['unit']).to eq('celsius')
        expect(data[0]['timestamp']).to eq('2025-10-03T12:00:00Z')

        expect(data[1]['sensor_type']).to eq('humidity')
        expect(data[1]['value']).to eq(40.2)
        expect(data[1]['unit']).to eq('%')
        expect(data[1]['timestamp']).to eq('2025-10-03T12:00:00Z')
      end
    end

    context 'with text format' do
      before do
        cli.instance_variable_set(:@options, { format: 'text', backend: 'simulation' })
      end

      it 'outputs human-readable text with sensor values' do
        output = capture_stdout { cli.send(:output_readings, readings) }

        expect(output).to include('temperature: 24.1 celsius')
        expect(output).to include('humidity: 40.2 %')
      end
    end
  end

  describe '#list_sensors' do
    it 'includes all implemented sensors' do
      output = capture_stdout { cli.send(:list_sensors) }

      expect(output).to include('dht22')
      expect(output).to include('bme280')
      expect(output).to include('ds18b20')
      expect(output).to include('sht31')
      expect(output).to include('bh1750')
      expect(output).to include('tsl2561')
      expect(output).to include('ina219')
      expect(output).to include('adxl345')
      expect(output).to include('scd30')
      expect(output).to include('yf_s201')
      expect(output).to include('neo6m')
    end

    it 'does not include unimplemented sensors' do
      output = capture_stdout { cli.send(:list_sensors) }

      expect(output).not_to include('bmp180')
      expect(output).not_to include('mcp9808')
    end
  end

  describe '#create_sensor' do
    before do
      cli.instance_variable_set(:@options, { backend: 'simulation', format: 'text' })
      cli.send(:setup_backends)
    end

    it 'creates an ADXL345 sensor' do
      sensor = cli.send(:create_sensor, 'adxl345', [])
      expect(sensor).to be_a(Dredger::IoT::Sensors::ADXL345)
    end

    it 'creates an SCD30 sensor' do
      sensor = cli.send(:create_sensor, 'scd30', [])
      expect(sensor).to be_a(Dredger::IoT::Sensors::SCD30)
    end

    it 'creates a YF-S201 sensor' do
      sensor = cli.send(:create_sensor, 'yf_s201', [])
      expect(sensor).to be_a(Dredger::IoT::Sensors::YFS201)
    end

    it 'creates a NEO-6M sensor' do
      sensor = cli.send(:create_sensor, 'neo6m', [])
      expect(sensor).to be_a(Dredger::IoT::Sensors::NEO6M)
    end
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
