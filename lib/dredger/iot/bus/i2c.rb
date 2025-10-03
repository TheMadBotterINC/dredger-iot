# frozen_string_literal: true

module Dredger
  module IoT
    module Bus
      # Minimal I2C abstraction. Defaults to Simulation backend.
      class I2C
        def initialize(backend: nil)
          @backend = backend || Simulation.new
        end

        # Write bytes to device address starting at optional register
        def write(addr, bytes, register: nil)
          @backend.write(addr, bytes, register: register)
        end

        # Read length bytes from device address optionally starting at register
        def read(addr, length, register: nil)
          @backend.read(addr, length, register: register)
        end

        # Simulation backend keeps a per-address register map
        class Simulation
          def initialize
            @devices = Hash.new { |h, k| h[k] = Hash.new(0) }
          end

          def write(addr, bytes, register: nil)
            raise ArgumentError, "bytes must be an Array of integers" unless bytes.is_a?(Array) && bytes.all? { |b| b.is_a?(Integer) }

            if register.nil?
              # Treat as sequential write starting at register 0
              bytes.each_with_index { |b, i| @devices[addr][i] = b & 0xFF }
            else
              bytes.each_with_index { |b, i| @devices[addr][register + i] = b & 0xFF }
            end
            true
          end

          def read(addr, length, register: nil)
            raise ArgumentError, "length must be positive" unless length.positive?

            start = register || 0
            (0...length).map { |i| @devices[addr][start + i] & 0xFF }
          end

          # For tests to seed device registers
          def seed(addr, register, bytes)
            bytes.each_with_index { |b, i| @devices[addr][register + i] = b & 0xFF }
          end
        end
      end
    end
  end
end
