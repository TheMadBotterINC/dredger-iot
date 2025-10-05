# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Dredger::IoT::Bus do
  describe Dredger::IoT::Bus::I2C::Simulation do
    it 'writes and reads without register (sequential from 0)' do
      sim = described_class.new
      bytes = [0xAA, 0xBB, 0xCC]
      sim.write(0x50, bytes)
      expect(sim.read(0x50, 3)).to eq(bytes)
    end

    it 'writes and reads with explicit register offset' do
      sim = described_class.new
      sim.write(0x50, [0x11, 0x22, 0x33], register: 0x10)
      expect(sim.read(0x50, 3, register: 0x10)).to eq([0x11, 0x22, 0x33])
    end

    it 'seeds data and reads back via helper' do
      sim = described_class.new
      sim.seed(0x60, 0x05, [1, 2, 3, 4])
      expect(sim.read(0x60, 4, register: 0x05)).to eq([1, 2, 3, 4])
    end

    it 'raises on invalid arguments' do
      sim = described_class.new
      expect { sim.write(0x50, 'not-bytes') }.to raise_error(ArgumentError)
      expect { sim.read(0x50, 0) }.to raise_error(ArgumentError)
    end
  end

  describe Dredger::IoT::Bus::GPIO::Simulation do
    it 'sets direction and writes/reads values' do
      sim = described_class.new
      sim.set_direction('GPIO17', :out)
      sim.write('GPIO17', 1)
      expect(sim.read('GPIO17')).to eq(1)

      sim.set_direction('GPIO18', :in)
      sim.inject_input('GPIO18', 0)
      expect(sim.read('GPIO18')).to eq(0)
    end

    it 'raises on invalid direction and invalid value' do
      sim = described_class.new
      expect { sim.set_direction('x', :foo) }.to raise_error(ArgumentError)

      sim.set_direction('x', :out)
      expect { sim.write('x', 2) }.to raise_error(ArgumentError)
      expect { sim.inject_input('x', 3) }.to raise_error(ArgumentError)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
