# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Recipe do
  let(:ingredient) { Cooklang::Ingredient.new(name: "flour", quantity: 125, unit: "g") }
  let(:cookware) { Cooklang::Cookware.new(name: "pan") }
  let(:timer) { Cooklang::Timer.new(duration: 5, unit: "minutes") }
  let(:step) { Cooklang::Step.new(segments: ["Mix the ", { type: :ingredient, name: "flour" }]) }
  let(:metadata) { Cooklang::Metadata.new(title: "Test Recipe") }

  describe "#initialize" do
    it "creates a recipe with all components" do
      recipe = described_class.new(
        ingredients: [ingredient],
        cookware: [cookware],
        timers: [timer],
        steps: [step],
        metadata: metadata
      )

      expect(recipe.ingredients).to eq([ingredient])
      expect(recipe.cookware).to eq([cookware])
      expect(recipe.timers).to eq([timer])
      expect(recipe.steps).to eq([step])
      expect(recipe.metadata).to eq(metadata)
    end

    it "freezes arrays to prevent modification" do
      recipe = described_class.new(
        ingredients: [ingredient],
        cookware: [cookware],
        timers: [timer],
        steps: [step],
        metadata: metadata
      )

      expect(recipe.ingredients).to be_frozen
      expect(recipe.cookware).to be_frozen
      expect(recipe.timers).to be_frozen
      expect(recipe.steps).to be_frozen
    end
  end

  describe "#ingredients_hash" do
    it "returns ingredients as a hash with quantity and unit" do
      ingredient1 = Cooklang::Ingredient.new(name: "flour", quantity: 125, unit: "g")
      ingredient2 = Cooklang::Ingredient.new(name: "salt", quantity: 1, unit: "pinch")

      recipe = described_class.new(
        ingredients: [ingredient1, ingredient2],
        cookware: [],
        timers: [],
        steps: [],
        metadata: Cooklang::Metadata.new
      )

      expected = {
        "flour" => { quantity: 125, unit: "g" },
        "salt" => { quantity: 1, unit: "pinch" }
      }

      expect(recipe.ingredients_hash).to eq(expected)
    end

    it "omits nil values" do
      ingredient = Cooklang::Ingredient.new(name: "salt")

      recipe = described_class.new(
        ingredients: [ingredient],
        cookware: [],
        timers: [],
        steps: [],
        metadata: Cooklang::Metadata.new
      )

      expect(recipe.ingredients_hash).to eq({ "salt" => {} })
    end
  end

  describe "#steps_text" do
    it "returns text representation of steps" do
      step1 = Cooklang::Step.new(segments: ["Mix the ingredients"])
      step2 = Cooklang::Step.new(segments: ["Cook for ", { type: :timer, name: "timer" }])

      recipe = described_class.new(
        ingredients: [],
        cookware: [],
        timers: [],
        steps: [step1, step2],
        metadata: Cooklang::Metadata.new
      )

      expect(recipe.steps_text).to eq(["Mix the ingredients", "Cook for timer"])
    end
  end

  describe "#to_h" do
    it "returns complete hash representation" do
      recipe = described_class.new(
        ingredients: [ingredient],
        cookware: [cookware],
        timers: [timer],
        steps: [step],
        metadata: metadata
      )

      hash = recipe.to_h

      expect(hash[:ingredients]).to eq([ingredient.to_h])
      expect(hash[:cookware]).to eq([cookware.to_h])
      expect(hash[:timers]).to eq([timer.to_h])
      expect(hash[:steps]).to eq([step.to_h])
      expect(hash[:metadata]).to eq(metadata.to_h)
    end
  end

  describe "#==" do
    it "returns true for recipes with same content" do
      recipe1 = described_class.new(
        ingredients: [ingredient],
        cookware: [cookware],
        timers: [timer],
        steps: [step],
        metadata: metadata
      )

      recipe2 = described_class.new(
        ingredients: [ingredient],
        cookware: [cookware],
        timers: [timer],
        steps: [step],
        metadata: metadata
      )

      expect(recipe1).to eq(recipe2)
    end

    it "returns false for recipes with different content" do
      recipe1 = described_class.new(
        ingredients: [ingredient],
        cookware: [],
        timers: [],
        steps: [],
        metadata: Cooklang::Metadata.new
      )

      recipe2 = described_class.new(
        ingredients: [],
        cookware: [cookware],
        timers: [],
        steps: [],
        metadata: Cooklang::Metadata.new
      )

      expect(recipe1).not_to eq(recipe2)
    end

    it "returns false for non-Recipe objects" do
      recipe = described_class.new(
        ingredients: [],
        cookware: [],
        timers: [],
        steps: [],
        metadata: Cooklang::Metadata.new
      )

      expect(recipe).not_to eq("not a recipe")
    end
  end
end
