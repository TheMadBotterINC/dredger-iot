# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dredger::IoT::Scheduler do
  describe ".periodic_with_jitter" do
    it "yields positive intervals with jitter bounded by ratio" do
      enum = described_class.periodic_with_jitter(base_interval: 10.0, jitter_ratio: 0.2)
      samples = enum.take(20)
      expect(samples).to all(be > 0.0)
      expect(samples.max).to be <= 12.0
      expect(samples.min).to be >= 8.0
    end

    it "validates arguments" do
      expect { described_class.periodic_with_jitter(base_interval: 0, jitter_ratio: 0.1) }.to raise_error(ArgumentError)
      expect { described_class.periodic_with_jitter(base_interval: 1, jitter_ratio: -0.1) }.to raise_error(ArgumentError)
      expect { described_class.periodic_with_jitter(base_interval: 1, jitter_ratio: 1.1) }.to raise_error(ArgumentError)
    end
  end

  describe ".exponential_backoff" do
    it "grows up to the max and stops at attempts" do
      enum = described_class.exponential_backoff(initial: 1.0, factor: 2.0, max: 5.0, attempts: 5)
      expect(enum.to_a).to eq([1.0, 2.0, 4.0, 5.0, 5.0])
    end

    it "validates arguments" do
      expect { described_class.exponential_backoff(initial: 0, factor: 2.0, max: 10.0) }.to raise_error(ArgumentError)
      expect { described_class.exponential_backoff(initial: 1.0, factor: 0.5, max: 10.0) }.to raise_error(ArgumentError)
      expect { described_class.exponential_backoff(initial: 5.0, factor: 2.0, max: 1.0) }.to raise_error(ArgumentError)
    end
  end
end