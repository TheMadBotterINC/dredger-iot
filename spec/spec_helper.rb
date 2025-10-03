# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  minimum_coverage 100
  minimum_coverage_by_file 100
  add_filter %r{^/spec/}
end

require "bundler/setup"
require "dredger/iot"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.order = :random
  Kernel.srand config.seed
end