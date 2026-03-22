# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe Dredger::IoT::Sensors::NEO6MProvider do
  let(:provider) { described_class.new(baud_rate: 9600, timeout: 5) }

  describe '#read_position' do
    it 'parses GGA and RMC sentences into position data' do
      gga = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\n"
      rmc = "$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A\n"
      serial = StringIO.new(gga + rmc)
      allow(serial).to receive(:wait_readable).and_return(true)

      allow(File).to receive(:open).with('/dev/ttyAMA0', 'r+').and_yield(serial)

      result = provider.read_position('/dev/ttyAMA0')

      # 48 degrees + 7.038 minutes = 48 + 7.038/60 = 48.1173
      expect(result[:latitude]).to be_within(0.001).of(48.1173)
      # 11 degrees + 31.0 minutes = 11 + 31.0/60 = 11.516667
      expect(result[:longitude]).to be_within(0.001).of(11.516667)
      expect(result[:altitude]).to be_within(0.1).of(545.4)
      # 22.4 knots * 1.852 = 41.4848 km/h
      expect(result[:speed]).to be_within(0.1).of(41.48)
      expect(result[:satellites]).to eq(8)
      expect(result[:fix_quality]).to eq(1)
    end

    it 'handles GGA-only data (no RMC)' do
      gga = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47\n"
      serial = StringIO.new(gga)
      allow(serial).to receive(:wait_readable).and_return(true, false)

      allow(File).to receive(:open).with('/dev/ttyAMA0', 'r+').and_yield(serial)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1), Time.at(6))

      result = provider.read_position('/dev/ttyAMA0')

      expect(result[:latitude]).to be_within(0.001).of(48.1173)
      expect(result[:speed]).to eq(0.0) # no RMC data
    end

    it 'raises on timeout with no valid sentences' do
      serial = StringIO.new("")
      allow(serial).to receive(:wait_readable).and_return(false)

      allow(File).to receive(:open).with('/dev/ttyAMA0', 'r+').and_yield(serial)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(6))

      expect { provider.read_position('/dev/ttyAMA0') }.to raise_error(IOError, /GPS timeout/)
    end

    it 'skips GGA sentences with no fix' do
      # fix_quality=0 means no fix
      gga_nofix = "$GPGGA,123519,4807.038,N,01131.000,E,0,00,0.0,0.0,M,0.0,M,,*47\n"
      serial = StringIO.new(gga_nofix)
      allow(serial).to receive(:wait_readable).and_return(true, false)

      allow(File).to receive(:open).with('/dev/ttyAMA0', 'r+').and_yield(serial)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1), Time.at(6))

      expect { provider.read_position('/dev/ttyAMA0') }.to raise_error(IOError, /GPS timeout/)
    end

    it 'handles southern and western coordinates' do
      gga = "$GPGGA,123519,3346.482,S,07034.756,W,1,06,1.2,52.4,M,0.0,M,,*47\n"
      serial = StringIO.new(gga)
      allow(serial).to receive(:wait_readable).and_return(true, false)

      allow(File).to receive(:open).with('/dev/ttyAMA0', 'r+').and_yield(serial)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1), Time.at(6))

      result = provider.read_position('/dev/ttyAMA0')

      expect(result[:latitude]).to be < 0
      expect(result[:longitude]).to be < 0
    end

    it 'handles GLONASS prefixed sentences (GN)' do
      gga = "$GNGGA,123519,4807.038,N,01131.000,E,1,12,0.8,100.0,M,46.9,M,,*47\n"
      serial = StringIO.new(gga)
      allow(serial).to receive(:wait_readable).and_return(true, false)

      allow(File).to receive(:open).with('/dev/ttyAMA0', 'r+').and_yield(serial)
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(1), Time.at(6))

      result = provider.read_position('/dev/ttyAMA0')

      expect(result[:satellites]).to eq(12)
    end
  end

  describe '#parse_coordinate' do
    it 'parses latitude format (ddmm.mmmm)' do
      result = provider.send(:parse_coordinate, '4807.038', 'N')
      expect(result).to be_within(0.0001).of(48.1173)
    end

    it 'parses longitude format (dddmm.mmmm)' do
      result = provider.send(:parse_coordinate, '01131.000', 'E')
      expect(result).to be_within(0.0001).of(11.5167)
    end

    it 'returns 0.0 for empty coordinate' do
      expect(provider.send(:parse_coordinate, '', 'N')).to eq(0.0)
      expect(provider.send(:parse_coordinate, nil, 'N')).to eq(0.0)
    end

    it 'negates for S and W directions' do
      south = provider.send(:parse_coordinate, '4807.038', 'S')
      west = provider.send(:parse_coordinate, '01131.000', 'W')

      expect(south).to be < 0
      expect(west).to be < 0
    end
  end
end
