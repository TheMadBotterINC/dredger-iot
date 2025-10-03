# frozen_string_literal: true

require_relative "iot/version"
require_relative "iot/reading"
require_relative "iot/scheduler"

module Dredger
  module IoT
    class Error < StandardError; end
  end
end