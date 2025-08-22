# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Timer do
  describe "#initialize" do
    it "creates timer with name, duration and unit" do
      timer = described_class.new(name: "baking", duration: 30, unit: "minutes")

      expect(timer.name).to eq("baking")
      expect(timer.duration).to eq(30)
      expect(timer.unit).to eq("minutes")
    end

    it "creates timer without name" do
      timer = described_class.new(duration: 15, unit: "seconds")

      expect(timer.name).to be_nil
      expect(timer.duration).to eq(15)
      expect(timer.unit).to eq("seconds")
    end

    it "converts name to string and freezes it" do
      timer = described_class.new(name: :cooking, duration: 5, unit: "minutes")

      expect(timer.name).to eq("cooking")
      expect(timer.name).to be_frozen
    end

    it "converts unit to string and freezes it" do
      timer = described_class.new(duration: 5, unit: :minutes)

      expect(timer.unit).to eq("minutes")
      expect(timer.unit).to be_frozen
    end
  end

  describe "#to_s" do
    it "returns duration and unit when no name" do
      timer = described_class.new(duration: 5, unit: "minutes")
      expect(timer.to_s).to eq("5 minutes")
    end

    it "includes name when present" do
      timer = described_class.new(name: "baking", duration: 30, unit: "minutes")
      expect(timer.to_s).to eq("baking: 30 minutes")
    end
  end

  describe "#to_h" do
    it "returns hash with all present attributes" do
      timer = described_class.new(name: "baking", duration: 30, unit: "minutes")

      expected = {
        name: "baking",
        duration: 30,
        unit: "minutes"
      }

      expect(timer.to_h).to eq(expected)
    end

    it "omits nil attributes" do
      timer = described_class.new(duration: 5, unit: "minutes")

      expected = {
        duration: 5,
        unit: "minutes"
      }

      expect(timer.to_h).to eq(expected)
    end
  end

  describe "#==" do
    it "returns true for timers with same attributes" do
      timer1 = described_class.new(name: "cooking", duration: 5, unit: "minutes")
      timer2 = described_class.new(name: "cooking", duration: 5, unit: "minutes")

      expect(timer1).to eq(timer2)
    end

    it "returns false for timers with different names" do
      timer1 = described_class.new(name: "cooking", duration: 5, unit: "minutes")
      timer2 = described_class.new(name: "baking", duration: 5, unit: "minutes")

      expect(timer1).not_to eq(timer2)
    end

    it "returns false for timers with different durations" do
      timer1 = described_class.new(duration: 5, unit: "minutes")
      timer2 = described_class.new(duration: 10, unit: "minutes")

      expect(timer1).not_to eq(timer2)
    end

    it "returns false for non-Timer objects" do
      timer = described_class.new(duration: 5, unit: "minutes")

      expect(timer).not_to eq("5 minutes")
    end
  end

  describe "#total_seconds" do
    it "converts seconds to seconds" do
      timer = described_class.new(duration: 30, unit: "seconds")
      expect(timer.total_seconds).to eq(30)
    end

    it "converts minutes to seconds" do
      timer = described_class.new(duration: 5, unit: "minutes")
      expect(timer.total_seconds).to eq(300)
    end

    it "converts hours to seconds" do
      timer = described_class.new(duration: 2, unit: "hours")
      expect(timer.total_seconds).to eq(7200)
    end

    it "converts days to seconds" do
      timer = described_class.new(duration: 1, unit: "days")
      expect(timer.total_seconds).to eq(86_400)
    end

    it "handles various unit formats" do
      expect(described_class.new(duration: 30, unit: "sec").total_seconds).to eq(30)
      expect(described_class.new(duration: 30, unit: "s").total_seconds).to eq(30)
      expect(described_class.new(duration: 5, unit: "min").total_seconds).to eq(300)
      expect(described_class.new(duration: 5, unit: "m").total_seconds).to eq(300)
      expect(described_class.new(duration: 2, unit: "hr").total_seconds).to eq(7200)
      expect(described_class.new(duration: 2, unit: "h").total_seconds).to eq(7200)
      expect(described_class.new(duration: 1, unit: "d").total_seconds).to eq(86_400)
    end

    it "handles case insensitive units" do
      timer = described_class.new(duration: 5, unit: "MINUTES")
      expect(timer.total_seconds).to eq(300)
    end

    it "returns duration for unknown units" do
      timer = described_class.new(duration: 10, unit: "unknown")
      expect(timer.total_seconds).to eq(10)
    end
  end

  describe "#has_name?" do
    it "returns true when name is present" do
      timer = described_class.new(name: "cooking", duration: 5, unit: "minutes")
      expect(timer).to have_name
    end

    it "returns false when name is nil" do
      timer = described_class.new(duration: 5, unit: "minutes")
      expect(timer).not_to have_name
    end
  end

  describe "#hash" do
    it "generates same hash for equal timers" do
      timer1 = described_class.new(name: "cooking", duration: 5, unit: "minutes")
      timer2 = described_class.new(name: "cooking", duration: 5, unit: "minutes")

      expect(timer1.hash).to eq(timer2.hash)
    end

    it "generates different hash for different timers" do
      timer1 = described_class.new(duration: 5, unit: "minutes")
      timer2 = described_class.new(duration: 10, unit: "minutes")

      expect(timer1.hash).not_to eq(timer2.hash)
    end
  end
end
