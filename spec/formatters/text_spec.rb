# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Formatters::Text do
  let(:recipe) do
    Cooklang::Recipe.new(
      ingredients: ingredients,
      steps: steps,
      cookware: [],
      timers: [],
      metadata: {},
      sections: [],
      notes: []
    )
  end
  let(:formatter) { described_class.new(recipe) }

  describe "#to_s" do
    context "with ingredients only" do
      let(:ingredients) do
        [
          Cooklang::Ingredient.new(name: "flour", quantity: 125, unit: "g"),
          Cooklang::Ingredient.new(name: "milk", quantity: 250, unit: "ml"),
          Cooklang::Ingredient.new(name: "eggs", quantity: 3),
          Cooklang::Ingredient.new(name: "butter"),
          Cooklang::Ingredient.new(name: "sea salt", quantity: 1, unit: "pinch")
        ]
      end
      let(:steps) { [] }

      it "formats ingredients with aligned columns" do
        expected = <<~OUTPUT.strip
          Ingredients:
              flour       125 g
              milk        250 ml
              eggs        3
              butter      some
              sea salt    1 pinch
        OUTPUT

        expect(formatter.to_s).to eq(expected)
      end
    end

    context "with steps only" do
      let(:ingredients) { [] }
      let(:steps) do
        [
          Cooklang::Step.new(segments: [
                               { type: "text", value: "Crack the " },
                               { type: "ingredient", value: "eggs", name: "eggs" },
                               { type: "text", value: " into a blender" }
                             ]),
          Cooklang::Step.new(segments: [
                               { type: "text", value: "Pour into a bowl and leave to stand for " },
                               { type: "timer", value: "15 minutes", name: nil },
                               { type: "text", value: "." }
                             ])
        ]
      end

      it "formats steps with numbered list" do
        expected = <<~OUTPUT.strip
          Steps:
              1. Crack the eggs into a blender
              2. Pour into a bowl and leave to stand for 15 minutes.
        OUTPUT

        expect(formatter.to_s).to eq(expected)
      end
    end

    context "with both ingredients and steps" do
      let(:ingredients) do
        [
          Cooklang::Ingredient.new(name: "butter"),
          Cooklang::Ingredient.new(name: "eggs", quantity: 3),
          Cooklang::Ingredient.new(name: "flour", quantity: 125, unit: "g"),
          Cooklang::Ingredient.new(name: "milk", quantity: 250, unit: "ml"),
          Cooklang::Ingredient.new(name: "sea salt", quantity: 1, unit: "pinch")
        ]
      end
      let(:steps) do
        [
          Cooklang::Step.new(segments: [
                               { type: "text", value: "Crack the " },
                               { type: "ingredient", value: "eggs", name: "eggs" },
                               { type: "text", value: " into a blender, then add the " },
                               { type: "ingredient", value: "flour", name: "flour" },
                               { type: "text", value: ", " },
                               { type: "ingredient", value: "milk", name: "milk" },
                               { type: "text", value: " and " },
                               { type: "ingredient", value: "sea salt", name: "sea salt" },
                               { type: "text", value: "." }
                             ]),
          Cooklang::Step.new(segments: [
                               { type: "text", value: "Pour into a bowl and leave to stand for " },
                               { type: "timer", value: "15 minutes", name: nil },
                               { type: "text", value: "." }
                             ]),
          Cooklang::Step.new(segments: [
                               { type: "text", value: "Melt the " },
                               { type: "ingredient", value: "butter", name: "butter" },
                               { type: "text", value: " in a large non-stick " },
                               { type: "cookware", value: "frying pan", name: "frying pan" },
                               { type: "text", value: "." }
                             ])
        ]
      end

      it "formats complete recipe" do
        expected = <<~OUTPUT.strip
          Ingredients:
              butter      some
              eggs        3
              flour       125 g
              milk        250 ml
              sea salt    1 pinch

          Steps:
              1. Crack the eggs into a blender, then add the flour, milk and sea salt.
              2. Pour into a bowl and leave to stand for 15 minutes.
              3. Melt the butter in a large non-stick frying pan.
        OUTPUT

        expect(formatter.to_s).to eq(expected)
      end
    end

    context "with empty recipe" do
      let(:ingredients) { [] }
      let(:steps) { [] }

      it "returns empty string" do
        expect(formatter.to_s).to eq("")
      end
    end

    context "with various ingredient formats" do
      let(:ingredients) do
        [
          Cooklang::Ingredient.new(name: "onion", quantity: 1),
          Cooklang::Ingredient.new(name: "olive oil", unit: "drizzle"),
          Cooklang::Ingredient.new(name: "salt"),
          Cooklang::Ingredient.new(name: "pepper", quantity: "some", unit: "grinds")
        ]
      end
      let(:steps) { [] }

      it "handles missing quantities and units gracefully" do
        expected = <<~OUTPUT.strip
          Ingredients:
              onion        1
              olive oil    drizzle
              salt         some
              pepper       some grinds
        OUTPUT

        expect(formatter.to_s).to eq(expected)
      end
    end
  end

  describe "#format_quantity_unit" do
    let(:formatter) { described_class.new(recipe) }
    let(:recipe) { double("recipe") }

    it "formats quantity with unit" do
      ingredient = Cooklang::Ingredient.new(name: "flour", quantity: 125, unit: "g")
      expect(formatter.send(:format_quantity_unit, ingredient)).to eq("125 g")
    end

    it "formats quantity without unit" do
      ingredient = Cooklang::Ingredient.new(name: "eggs", quantity: 3)
      expect(formatter.send(:format_quantity_unit, ingredient)).to eq("3")
    end

    it "formats unit without quantity" do
      ingredient = Cooklang::Ingredient.new(name: "olive oil", unit: "drizzle")
      expect(formatter.send(:format_quantity_unit, ingredient)).to eq("drizzle")
    end

    it "handles missing quantity and unit" do
      ingredient = Cooklang::Ingredient.new(name: "salt")
      expect(formatter.send(:format_quantity_unit, ingredient)).to eq("some")
    end
  end
end
