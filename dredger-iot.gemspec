# frozen_string_literal: true

Gem::Specification.new do |spec|
spec.name          = 'dredger-iot'
spec.version       = File.read(File.join(__dir__, 'lib', 'dredger', 'iot', 'version.rb')).match(/VERSION\s*=\s*\"([^\"]+)\"/)[1]
spec.authors       = ['The Mad Botter INC']
spec.email         = ['opensource@themadbotter.com']

spec.summary       = 'Generic hardware integration for embedded Linux (GPIO, I2C) with sensor drivers.'
spec.description   = 'FFI-based GPIO and I2C access with Beaglebone pin mapping, sensor drivers (DHT22, BME280), and simple scheduling utilities.'
spec.homepage      = 'https://github.com/TheMadBotterINC/dredger-iot'
spec.license       = 'MIT'

spec.required_ruby_version = '>= 3.3'

spec.metadata['homepage_uri'] = spec.homepage
spec.metadata['source_code_uri'] = spec.homepage
spec.metadata['changelog_uri'] = 'https://github.com/TheMadBotterINC/dredger-iot/releases'

  spec.files = Dir.chdir(__dir__) do
Dir['lib/**/*', 'LICENSE.txt', 'README.md']
  end
spec.bindir        = 'exe'
  spec.executables   = []
spec.require_paths = ['lib']

spec.add_dependency 'ffi', '>= 1.15'

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", ">= 3.12"
  spec.add_development_dependency "simplecov", ">= 0.22.0"
  spec.add_development_dependency "rubocop", ">= 1.63"
  spec.add_development_dependency "rubocop-rspec", ">= 3.0"
  spec.add_development_dependency "rubocop-performance", ">= 1.20"
  spec.add_development_dependency "rubocop-rails-omakase", ">= 1.0"
end
