# frozen_string_literal: true

require_relative "iot/version"
require_relative "iot/reading"
require_relative "iot/scheduler"
require_relative "iot/bus"
require_relative "iot/pins"
require_relative "iot/sensors"

module Dredger
  module IoT
    class Error < StandardError; end
  end
end
