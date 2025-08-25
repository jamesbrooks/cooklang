# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Section do
  describe "#initialize" do
    it "creates section with name" do
      section = described_class.new(name: "Preparation")
      expect(section.name).to eq("Preparation")
    end

    it "converts name to string and freezes it" do
      section = described_class.new(name: 123)
      expect(section.name).to eq("123")
      expect(section.name).to be_frozen
    end
  end

  describe "#to_s" do
    it "returns name" do
      section = described_class.new(name: "Cooking")
      expect(section.to_s).to eq("Cooking")
    end
  end

  describe "#to_h" do
    it "returns hash representation" do
      section = described_class.new(name: "Preparation")
      expect(section.to_h).to eq({ name: "Preparation", steps: [] })
    end
  end

  describe "#==" do
    it "returns true for sections with same name" do
      section1 = described_class.new(name: "Prep")
      section2 = described_class.new(name: "Prep")
      expect(section1 == section2).to be_truthy
    end

    it "returns false for sections with different names" do
      section1 = described_class.new(name: "Prep")
      section2 = described_class.new(name: "Cook")
      expect(section1 == section2).to be_falsey
    end

    it "returns false for non-Section objects" do
      section = described_class.new(name: "Prep")
      expect(section == "Prep").to be_falsey
    end
  end

  describe "#hash" do
    it "generates same hash for equal sections" do
      section1 = described_class.new(name: "Test")
      section2 = described_class.new(name: "Test")
      expect(section1.hash).to eq(section2.hash)
    end

    it "generates different hash for different sections" do
      section1 = described_class.new(name: "Test 1")
      section2 = described_class.new(name: "Test 2")
      expect(section1.hash).not_to eq(section2.hash)
    end
  end
end
