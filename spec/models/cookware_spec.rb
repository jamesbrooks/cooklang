# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Cookware do
  describe "#initialize" do
    it "creates cookware with name and quantity" do
      cookware = described_class.new(name: "frying pan", quantity: 2)

      expect(cookware.name).to eq("frying pan")
      expect(cookware.quantity).to eq(2)
    end

    it "creates cookware with only name" do
      cookware = described_class.new(name: "bowl")

      expect(cookware.name).to eq("bowl")
      expect(cookware.quantity).to be_nil
    end

    it "converts name to string and freezes it" do
      cookware = described_class.new(name: :pan)

      expect(cookware.name).to eq("pan")
      expect(cookware.name).to be_frozen
    end
  end

  describe "#to_s" do
    it "returns name only when no quantity" do
      cookware = described_class.new(name: "bowl")
      expect(cookware.to_s).to eq("bowl")
    end

    it "includes quantity when present" do
      cookware = described_class.new(name: "frying pan", quantity: 2)
      expect(cookware.to_s).to eq("frying pan (2)")
    end
  end

  describe "#to_h" do
    it "returns hash with all present attributes" do
      cookware = described_class.new(name: "frying pan", quantity: 2)

      expected = {
        name: "frying pan",
        quantity: 2
      }

      expect(cookware.to_h).to eq(expected)
    end

    it "omits nil attributes" do
      cookware = described_class.new(name: "bowl")

      expect(cookware.to_h).to eq({ name: "bowl" })
    end
  end

  describe "#==" do
    it "returns true for cookware with same attributes" do
      cookware1 = described_class.new(name: "pan", quantity: 1)
      cookware2 = described_class.new(name: "pan", quantity: 1)

      expect(cookware1).to eq(cookware2)
    end

    it "returns false for cookware with different names" do
      cookware1 = described_class.new(name: "pan")
      cookware2 = described_class.new(name: "bowl")

      expect(cookware1).not_to eq(cookware2)
    end

    it "returns false for cookware with different quantities" do
      cookware1 = described_class.new(name: "pan", quantity: 1)
      cookware2 = described_class.new(name: "pan", quantity: 2)

      expect(cookware1).not_to eq(cookware2)
    end

    it "returns false for non-Cookware objects" do
      cookware = described_class.new(name: "pan")

      expect(cookware).not_to eq("pan")
    end
  end

  describe "#has_quantity?" do
    it "returns true when quantity is present" do
      cookware = described_class.new(name: "pan", quantity: 1)
      expect(cookware).to have_quantity
    end

    it "returns false when quantity is nil" do
      cookware = described_class.new(name: "pan")
      expect(cookware).not_to have_quantity
    end
  end

  describe "#hash" do
    it "generates same hash for equal cookware" do
      cookware1 = described_class.new(name: "pan", quantity: 1)
      cookware2 = described_class.new(name: "pan", quantity: 1)

      expect(cookware1.hash).to eq(cookware2.hash)
    end

    it "generates different hash for different cookware" do
      cookware1 = described_class.new(name: "pan")
      cookware2 = described_class.new(name: "bowl")

      expect(cookware1.hash).not_to eq(cookware2.hash)
    end
  end
end
