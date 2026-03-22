# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Dredger::IoT::Sensors::DS18B20Provider do
  let(:tmpdir) { Dir.mktmpdir }
  let(:provider) { described_class.new(base_path: tmpdir) }

  after { FileUtils.remove_entry(tmpdir) }

  describe '#read_temperature' do
    it 'rejects device_id with path traversal' do
      expect { provider.read_temperature('../../etc/passwd') }.to raise_error(ArgumentError, /Invalid DS18B20 device_id/)
    end

    it 'rejects device_id with wrong family code' do
      expect { provider.read_temperature('29-0000056789ab') }.to raise_error(ArgumentError, /Invalid DS18B20 device_id/)
    end

    it 'rejects device_id with uppercase hex' do
      expect { provider.read_temperature('28-0000056789AB') }.to raise_error(ArgumentError, /Invalid DS18B20 device_id/)
    end

    it 'rejects empty device_id' do
      expect { provider.read_temperature('') }.to raise_error(ArgumentError, /Invalid DS18B20 device_id/)
    end

    it 'accepts valid device_id format' do
      device_dir = File.join(tmpdir, '28-0000056789ab')
      FileUtils.mkdir_p(device_dir)
      File.write(File.join(device_dir, 'w1_slave'), <<~W1)
        73 01 4b 46 7f ff 0d 10 41 : crc=41 YES
        73 01 4b 46 7f ff 0d 10 41 t=23187
      W1

      temp = provider.read_temperature('28-0000056789ab')
      expect(temp).to be_within(0.001).of(23.187)
    end

    it 'raises on CRC failure' do
      device_dir = File.join(tmpdir, '28-0000056789ab')
      FileUtils.mkdir_p(device_dir)
      File.write(File.join(device_dir, 'w1_slave'), <<~W1)
        73 01 4b 46 7f ff 0d 10 41 : crc=41 NO
        73 01 4b 46 7f ff 0d 10 41 t=23187
      W1

      expect { provider.read_temperature('28-0000056789ab') }.to raise_error(IOError, /CRC check failed/)
    end

    it 'raises when device file is missing' do
      expect { provider.read_temperature('28-0000056789ab') }.to raise_error(IOError, /device not found/)
    end

    it 'handles negative temperatures' do
      device_dir = File.join(tmpdir, '28-00000abcdef0')
      FileUtils.mkdir_p(device_dir)
      File.write(File.join(device_dir, 'w1_slave'), <<~W1)
        5e ff 4b 46 7f ff 0d 10 27 : crc=27 YES
        5e ff 4b 46 7f ff 0d 10 27 t=-10125
      W1

      temp = provider.read_temperature('28-00000abcdef0')
      expect(temp).to be_within(0.001).of(-10.125)
    end
  end

  describe '#list_devices' do
    it 'returns only 28-* devices' do
      FileUtils.mkdir_p(File.join(tmpdir, '28-000001'))
      FileUtils.mkdir_p(File.join(tmpdir, '28-000002'))
      FileUtils.mkdir_p(File.join(tmpdir, 'w1_bus_master1'))

      devices = provider.list_devices
      expect(devices).to contain_exactly('28-000001', '28-000002')
    end

    it 'returns empty array when base path does not exist' do
      provider_missing = described_class.new(base_path: '/nonexistent/path')
      expect(provider_missing.list_devices).to eq([])
    end
  end
end
