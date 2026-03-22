# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 95, branch: 80
  minimum_coverage_by_file line: 80, branch: 50
  add_filter %r{^/spec/}
  add_filter %r{/lib/dredger/iot/version\.rb$}
  add_filter %r{/lib/dredger/iot\.rb$}
  add_filter %r{/lib/dredger/iot/bus\.rb$}
  add_filter %r{/lib/dredger/iot/pins\.rb$}
  add_filter %r{/lib/dredger/iot/sensors\.rb$}
  # FFI backends require hardware/kernel modules — cannot be tested in CI
  add_filter %r{/lib/dredger/iot/bus/gpio_libgpiod\.rb$}
  add_filter %r{/lib/dredger/iot/bus/i2c_linux\.rb$}
  add_filter %r{/lib/dredger/iot/bus/auto\.rb$}
  # DHT22 provider requires microsecond GPIO timing (C extension needed)
  add_filter %r{/lib/dredger/iot/sensors/dht22_provider\.rb$}
  # CLI executable excluded from branch coverage
  add_filter %r{/bin/dredger$}
end

require 'bundler/setup'
require 'dredger/iot'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.order = :random
  Kernel.srand config.seed
end
