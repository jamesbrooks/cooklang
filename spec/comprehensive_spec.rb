# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Comprehensive Cooklang Implementation" do
  let(:parser) { Cooklang::Parser.new }

  describe "Core Features from SPEC.md" do
    context "Ingredients (@)" do
      it "parses single word ingredients" do
        recipe = parser.parse("@salt")
        expect(recipe.ingredients.first.name).to eq("salt")
        expect(recipe.ingredients.first.quantity).to eq("some")
      end

      it "parses multi-word ingredients with {}" do
        recipe = parser.parse("@ground black pepper{}")
        expect(recipe.ingredients.first.name).to eq("ground black pepper")
      end

      it "parses ingredients with quantity" do
        recipe = parser.parse("@potato{2}")
        expect(recipe.ingredients.first.name).to eq("potato")
        expect(recipe.ingredients.first.quantity).to eq(2)
      end

      it "parses ingredients with quantity and unit" do
        recipe = parser.parse("@bacon strips{1%kg}")
        expect(recipe.ingredients.first.name).to eq("bacon strips")
        expect(recipe.ingredients.first.quantity).to eq(1)
        expect(recipe.ingredients.first.unit).to eq("kg")
      end

      it "parses ingredients with notes/preparations" do
        recipe = parser.parse("@onion{1}(peeled and finely chopped)")
        expect(recipe.ingredients.first.name).to eq("onion")
        expect(recipe.ingredients.first.quantity).to eq(1)
        expect(recipe.ingredients.first.notes).to eq("peeled and finely chopped")
      end

      it "parses fractional quantities" do
        recipe = parser.parse("@syrup{1/2%tbsp}")
        expect(recipe.ingredients.first.quantity).to eq("1/2")
        expect(recipe.ingredients.first.unit).to eq("tbsp")
      end
    end

    context "Cookware (#)" do
      it "parses single word cookware" do
        recipe = parser.parse("Place into a #pot.")
        expect(recipe.cookware.first.name).to eq("pot")
      end

      it "parses multi-word cookware with {}" do
        recipe = parser.parse("Mash with a #potato masher{}.")
        expect(recipe.cookware.first.name).to eq("potato masher")
      end

      it "parses cookware with quantity" do
        recipe = parser.parse("Use #baking sheet{2}")
        expect(recipe.cookware.first.name).to eq("baking sheet")
        expect(recipe.cookware.first.quantity).to eq(2)
      end
    end

    context "Timers (~)" do
      it "parses anonymous timers" do
        recipe = parser.parse("Bake for ~{25%minutes}.")
        expect(recipe.timers.first.duration).to eq(25)
        expect(recipe.timers.first.unit).to eq("minutes")
        expect(recipe.timers.first.name).to be_nil
      end

      it "parses named timers" do
        recipe = parser.parse("Boil @eggs{2} for ~eggs{3%minutes}.")
        expect(recipe.timers.first.name).to eq("eggs")
        expect(recipe.timers.first.duration).to eq(3)
        expect(recipe.timers.first.unit).to eq("minutes")
      end
    end

    context "Steps" do
      it "separates steps by blank lines" do
        recipe = parser.parse("Step 1\n\nStep 2\n\nStep 3")
        expect(recipe.steps.size).to eq(3)
      end

      it "keeps multi-line steps together" do
        recipe = parser.parse("A step,\nthe same step.\n\nA different step.")
        expect(recipe.steps.size).to eq(2)
      end
    end

    context "Comments" do
      it "strips line comments with --" do
        recipe = parser.parse("-- Don't burn!\n@salt")
        expect(recipe.steps_text.join).not_to include("Don't burn")
        expect(recipe.ingredients.first.name).to eq("salt")
      end

      it "strips inline comments" do
        recipe = parser.parse("@potato{2} -- comment here")
        expect(recipe.steps_text.join).not_to include("comment here")
      end

      it "strips block comments with [- -]" do
        recipe = parser.parse("Add @milk{4%cup} [- TODO change -], mix")
        expect(recipe.steps_text.join).not_to include("TODO")
        expect(recipe.steps_text.join).to include("mix")
      end
    end

    context "Metadata" do
      it "parses YAML front matter" do
        input = "---\ntitle: Test Recipe\nservings: 4\n---\n@salt"
        recipe = parser.parse(input)
        expect(recipe.metadata["title"]).to eq("Test Recipe")
        expect(recipe.metadata["servings"]).to eq(4)
      end

      it "parses inline metadata with >>" do
        recipe = parser.parse(">> servings: 4\n@salt")
        expect(recipe.metadata["servings"]).to eq(4)
      end
    end

    context "Notes (>)" do
      it "parses notes with > prefix" do
        recipe = parser.parse("> Don't burn the roux!\n@salt")
        expect(recipe.notes.first.content).to eq("Don't burn the roux!")
      end

      it "distinguishes notes from metadata (>>)" do
        recipe = parser.parse(">> servings: 4\n> This is a note")
        expect(recipe.metadata["servings"]).to eq(4)
        expect(recipe.notes.first.content).to eq("This is a note")
      end
    end

    context "Sections (=)" do
      it "parses sections with single =" do
        recipe = parser.parse("= Dough\n@flour{200%g}")
        expect(recipe.sections.first.name).to eq("Dough")
      end

      it "parses sections with double ==" do
        recipe = parser.parse("== Filling ==\n@cheese{100%g}")
        expect(recipe.sections.first.name).to eq("Filling")
      end

      it "handles sections without names" do
        recipe = parser.parse("=\n@salt")
        expect(recipe.sections).to be_empty # unnamed sections not stored
      end
    end
  end

  describe "Advanced Features" do
    context "Short-hand preparations (in notes)" do
      it "handles preparation notes in parentheses" do
        recipe = parser.parse("@garlic{2%cloves}(peeled and minced)")
        expect(recipe.ingredients.first.notes).to eq("peeled and minced")
      end
    end
  end

  describe "Edge Cases and Unicode" do
    it "handles Unicode characters in ingredients" do
      recipe = parser.parse("Add @chilli⸫ then bake")
      expect(recipe.ingredients.first.name).to eq("chilli")
    end

    it "handles invalid syntax gracefully" do
      recipe = parser.parse("Message @ example")
      # Invalid ingredients should not be parsed
      expect(recipe.ingredients).to be_empty
    end
  end
end
