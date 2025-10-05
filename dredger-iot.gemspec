# frozen_string_literal: true

require_relative 'lib/dredger/iot/version'

Gem::Specification.new do |spec|
  spec.name          = 'dredger-iot'
  spec.version       = Dredger::IoT::VERSION
  spec.authors       = ['The Mad Botter INC']
  spec.email         = ['opensource@themadbotter.com']

  spec.summary       = 'Generic hardware integration for embedded Linux (GPIO, I2C) with sensor drivers.'
  spec.description   = <<~DESC
    Dredger-IoT provides FFI-based GPIO and I2C access for embedded Linux systems like Beaglebone Black.
    Features include: libgpiod GPIO backend, Linux i2c-dev I2C backend, simulation backends for testing,
    sensor drivers (DHT22, BME280, DS18B20, BMP180, MCP9808), Beaglebone pin label mapping, and
    scheduling utilities for periodic polling and exponential backoff.
  DESC
  spec.homepage      = 'https://github.com/TheMadBotterINC/dredger-iot'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.2'

  # Platform information
  # Note: Gem will install on any platform, but hardware backends require Linux
  # Simulation backends work on all platforms for testing
  spec.metadata['platforms'] = 'Hardware backends require Linux. Simulation works everywhere.'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/TheMadBotterINC/dredger-iot/blob/master/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/TheMadBotterINC/dredger-iot/issues'
  spec.metadata['documentation_uri'] = 'https://github.com/TheMadBotterINC/dredger-iot/blob/master/README.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Keywords for better discoverability
  spec.metadata['keywords'] = %w[
    iot embedded linux gpio i2c beaglebone raspberry-pi hardware sensors
    dht22 bme280 ds18b20 bmp180 mcp9808 libgpiod automation
  ].join(', ')

  spec.files = Dir.chdir(__dir__) do
    Dir['lib/**/*', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  end
  spec.bindir        = 'bin'
  spec.executables   = ['dredger']
  spec.require_paths = ['lib']

  spec.add_dependency 'ffi', '~> 1.15'

  spec.post_install_message = <<~MSG

        ═══════════════════════════════════════════════════════════════════
        #{'                                                               '}
                          _______________#{'                              '}
                         |  DREDGER-IoT  |#{'                            '}
                         |_______________|#{'                            '}
                        /|   ___     ___ |#{'                           '}
                       / |  |___|   |___|| #{'                          '}
                      /  |______________|  #{'                         '}
                 ====|========================|====#{'                   '}
                |    |    |-----------|     |    |#{'                   '}
                |    |____|           |_____|    |#{'                   '}
             ___|____|                         |____|___#{'             '}
        ~~~~{________|_________________________|________}~~~~~~~#{'     '}
          ~~      |  \\                     //  |         ~~~#{'        '}
                  |   \\___________________//   |#{'                    '}
                  |_____________________________|#{'                    '}
             ~~~       \\                 //          ~~~#{'            '}
                        \\_______________//#{'                          '}
        ═══════════════════════════════════════════════════════════════════
    Hardware Integration for Embedded Linux v#{Dredger::IoT::VERSION}
        ═══════════════════════════════════════════════════════════════════

        🎉 Thanks for installing!

        📚 Hardware Setup (kernel modules & permissions):
           https://github.com/TheMadBotterINC/dredger-iot#hardware-setup

        🚀 Quick Start:
           require 'dredger/iot'
           gpio = Dredger::IoT::Bus::Auto.gpio
           i2c  = Dredger::IoT::Bus::Auto.i2c

        💡 Supported Sensors:
           DHT22, BME280, DS18B20, BMP180, MCP9808

        📖 Full Documentation:
           https://github.com/TheMadBotterINC/dredger-iot

  MSG
end
