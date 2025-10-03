# frozen_string_literal: true

require 'ffi'

module Dredger
  module IoT
    module Bus
      # Linux I2C backend using i2c-dev via ioctl
      class I2C_Linux
        module LibC
          extend FFI::Library
          ffi_lib FFI::Library::LIBC
          attach_function :ioctl, [:int, :ulong, :ulong], :int
        end

        I2C_SLAVE = 0x0703

        def initialize(bus_path: '/dev/i2c-1')
          @bus_path = bus_path
        end

        def write(addr, bytes, register: nil)
          raise ArgumentError, 'bytes must be an Array of integers' unless bytes.is_a?(Array) && bytes.all?(Integer)

          File.open(@bus_path, 'r+b') do |f|
            set_slave(f, addr)
            data = register.nil? ? bytes : [register] + bytes
            f.write(data.pack('C*'))
          end
        end

        def read(addr, length, register: nil)
          raise ArgumentError, 'length must be positive' unless length.positive?

          File.open(@bus_path, 'r+b') do |f|
            set_slave(f, addr)
            f.write([register].pack('C')) unless register.nil?
            f.read(length).unpack('C*')
          end
        end

        private

        def set_slave(file, addr)
          rc = LibC.ioctl(file.fileno, I2C_SLAVE, addr)
          raise IOError, 'ioctl(I2C_SLAVE) failed' if rc.negative?
        end
      end
    end
  end
end