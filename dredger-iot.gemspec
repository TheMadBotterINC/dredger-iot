# frozen_string_literal: true

require_relative 'lib/dredger/iot/version'

Gem::Specification.new do |spec|
  spec.name          = 'dredger-iot'
  spec.version       = Dredger::IoT::VERSION
  spec.authors       = ['The Mad Botter INC']
  spec.email         = ['opensource@themadbotter.com']

  spec.summary       = 'Generic hardware integration for embedded Linux (GPIO, I2C) with sensor drivers.'
  spec.description   = 'FFI GPIO/I2C access for Beaglebone/Linux with pluggable sensors and simple scheduling.'
  spec.homepage      = 'https://github.com/TheMadBotterINC/dredger-iot'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/TheMadBotterINC/dredger-iot/releases'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    Dir['lib/**/*', 'LICENSE.txt', 'README.md']
  end
  spec.bindir        = 'exe'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.add_dependency 'ffi', '>= 1.15'
end
