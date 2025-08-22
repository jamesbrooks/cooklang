# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Ingredient do
  describe "#initialize" do
    it "creates an ingredient with all attributes" do
      ingredient = described_class.new(
        name: "flour",
        quantity: 125,
        unit: "g",
        notes: "sifted"
      )

      expect(ingredient.name).to eq("flour")
      expect(ingredient.quantity).to eq(125)
      expect(ingredient.unit).to eq("g")
      expect(ingredient.notes).to eq("sifted")
    end

    it "creates an ingredient with only name" do
      ingredient = described_class.new(name: "salt")

      expect(ingredient.name).to eq("salt")
      expect(ingredient.quantity).to be_nil
      expect(ingredient.unit).to be_nil
      expect(ingredient.notes).to be_nil
    end

    it "converts name to string and freezes it" do
      ingredient = described_class.new(name: :flour)

      expect(ingredient.name).to eq("flour")
      expect(ingredient.name).to be_frozen
    end

    it "converts unit to string and freezes it" do
      ingredient = described_class.new(name: "flour", unit: :grams)

      expect(ingredient.unit).to eq("grams")
      expect(ingredient.unit).to be_frozen
    end

    it "converts notes to string and freezes it" do
      ingredient = described_class.new(name: "flour", notes: :sifted)

      expect(ingredient.notes).to eq("sifted")
      expect(ingredient.notes).to be_frozen
    end
  end

  describe "#to_s" do
    it "returns name only when no other attributes" do
      ingredient = described_class.new(name: "salt")
      expect(ingredient.to_s).to eq("salt")
    end

    it "includes quantity when present" do
      ingredient = described_class.new(name: "flour", quantity: 125)
      expect(ingredient.to_s).to eq("flour 125")
    end

    it "includes unit when present" do
      ingredient = described_class.new(name: "flour", quantity: 125, unit: "g")
      expect(ingredient.to_s).to eq("flour 125 g")
    end

    it "includes notes when present" do
      ingredient = described_class.new(name: "flour", notes: "sifted")
      expect(ingredient.to_s).to eq("flour (sifted)")
    end

    it "includes all attributes when present" do
      ingredient = described_class.new(
        name: "flour",
        quantity: 125,
        unit: "g",
        notes: "sifted"
      )
      expect(ingredient.to_s).to eq("flour 125 g (sifted)")
    end
  end

  describe "#to_h" do
    it "returns hash with all present attributes" do
      ingredient = described_class.new(
        name: "flour",
        quantity: 125,
        unit: "g",
        notes: "sifted"
      )

      expected = {
        name: "flour",
        quantity: 125,
        unit: "g",
        notes: "sifted"
      }

      expect(ingredient.to_h).to eq(expected)
    end

    it "omits nil attributes" do
      ingredient = described_class.new(name: "salt")

      expect(ingredient.to_h).to eq({ name: "salt" })
    end
  end

  describe "#==" do
    it "returns true for ingredients with same attributes" do
      ingredient1 = described_class.new(name: "flour", quantity: 125, unit: "g")
      ingredient2 = described_class.new(name: "flour", quantity: 125, unit: "g")

      expect(ingredient1).to eq(ingredient2)
    end

    it "returns false for ingredients with different names" do
      ingredient1 = described_class.new(name: "flour")
      ingredient2 = described_class.new(name: "salt")

      expect(ingredient1).not_to eq(ingredient2)
    end

    it "returns false for ingredients with different quantities" do
      ingredient1 = described_class.new(name: "flour", quantity: 125)
      ingredient2 = described_class.new(name: "flour", quantity: 100)

      expect(ingredient1).not_to eq(ingredient2)
    end

    it "returns false for non-Ingredient objects" do
      ingredient = described_class.new(name: "flour")

      expect(ingredient).not_to eq("flour")
    end
  end

  describe "predicate methods" do
    describe "#has_quantity?" do
      it "returns true when quantity is present" do
        ingredient = described_class.new(name: "flour", quantity: 125)
        expect(ingredient).to have_quantity
      end

      it "returns false when quantity is nil" do
        ingredient = described_class.new(name: "flour")
        expect(ingredient).not_to have_quantity
      end
    end

    describe "#has_unit?" do
      it "returns true when unit is present" do
        ingredient = described_class.new(name: "flour", unit: "g")
        expect(ingredient).to have_unit
      end

      it "returns false when unit is nil" do
        ingredient = described_class.new(name: "flour")
        expect(ingredient).not_to have_unit
      end
    end

    describe "#has_notes?" do
      it "returns true when notes are present" do
        ingredient = described_class.new(name: "flour", notes: "sifted")
        expect(ingredient).to have_notes
      end

      it "returns false when notes are nil" do
        ingredient = described_class.new(name: "flour")
        expect(ingredient).not_to have_notes
      end
    end
  end

  describe "#hash" do
    it "generates same hash for equal ingredients" do
      ingredient1 = described_class.new(name: "flour", quantity: 125)
      ingredient2 = described_class.new(name: "flour", quantity: 125)

      expect(ingredient1.hash).to eq(ingredient2.hash)
    end

    it "generates different hash for different ingredients" do
      ingredient1 = described_class.new(name: "flour")
      ingredient2 = described_class.new(name: "salt")

      expect(ingredient1.hash).not_to eq(ingredient2.hash)
    end
  end
end
