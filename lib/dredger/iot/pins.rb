# frozen_string_literal: true

module Dredger
  module IoT
    module Pins
      PinRef = Struct.new(:label, :chip, :line, keyword_init: true) do
        def to_s
          chip && line ? "#{label}(chip#{chip}:#{line})" : label.to_s
        end
      end
    end
  end
end

require_relative 'pins/beaglebone'
require_relative 'pins/raspberry_pi'
