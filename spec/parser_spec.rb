# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Parser do
  let(:parser) { described_class.new }

  describe "#parse" do
    context "with simple ingredients" do
      it "parses single word ingredients" do
        recipe = parser.parse("Add @salt to taste.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("salt")
        expect(ingredient.quantity).to eq("some") # Default quantity per canonical tests
        expect(ingredient.unit).to be_nil
        expect(ingredient.notes).to be_nil
      end

      it "parses multi-word ingredients with braces" do
        recipe = parser.parse("Add @ground pepper{} to taste.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("ground pepper")
      end

      it "parses multi-word ingredients without braces (first word only)" do
        recipe = parser.parse("Add @ground pepper to taste.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("ground")
      end

      it "parses ingredients with quantities" do
        recipe = parser.parse("Use @flour{125%g} for the batter.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("flour")
        expect(ingredient.quantity).to eq(125)
        expect(ingredient.unit).to eq("g")
      end

      it "parses ingredients with quantities but no unit" do
        recipe = parser.parse("Crack @eggs{3} into bowl.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("eggs")
        expect(ingredient.quantity).to eq(3)
        expect(ingredient.unit).to be_nil
      end

      it "parses ingredients with notes" do
        recipe = parser.parse("Dice @onion{1}(large) finely.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("onion")
        expect(ingredient.quantity).to eq(1)
        expect(ingredient.unit).to be_nil
        expect(ingredient.notes).to eq("large")
      end

      it "parses ingredients with quantity, unit, and notes" do
        recipe = parser.parse("Add @butter{2%tbsp}(melted) to pan.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("butter")
        expect(ingredient.quantity).to eq(2)
        expect(ingredient.unit).to eq("tbsp")
        expect(ingredient.notes).to eq("melted")
      end

      it "parses ingredients with string quantities" do
        recipe = parser.parse("Add @salt{some} to taste.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("salt")
        expect(ingredient.quantity).to eq("some")
      end

      it "parses ingredients with decimal quantities" do
        recipe = parser.parse("Use @flour{1.5%cups} for batter.")

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.name).to eq("flour")
        expect(ingredient.quantity).to eq(1.5)
        expect(ingredient.unit).to eq("cups")
      end
    end

    context "with cookware" do
      it "parses simple cookware" do
        recipe = parser.parse("Heat the #pan over medium heat.")

        expect(recipe.cookware.size).to eq(1)
        cookware = recipe.cookware.first
        expect(cookware.name).to eq("pan")
        expect(cookware.quantity).to eq(1) # Default quantity per canonical tests
      end

      it "parses multi-word cookware with braces" do
        recipe = parser.parse("Use a #large skillet{} for cooking.")

        expect(recipe.cookware.size).to eq(1)
        cookware = recipe.cookware.first
        expect(cookware.name).to eq("large skillet")
      end

      it "parses multi-word cookware without braces (first word only)" do
        recipe = parser.parse("Use a #large skillet for cooking.")

        expect(recipe.cookware.size).to eq(1)
        cookware = recipe.cookware.first
        expect(cookware.name).to eq("large")
      end

      it "parses cookware with quantities" do
        recipe = parser.parse("Prepare #baking sheet{2} with parchment.")

        expect(recipe.cookware.size).to eq(1)
        cookware = recipe.cookware.first
        expect(cookware.name).to eq("baking sheet")
        expect(cookware.quantity).to eq(2)
      end

      it "parses cookware with string quantities" do
        recipe = parser.parse("Use #bowls{several} for prep.")

        expect(recipe.cookware.size).to eq(1)
        cookware = recipe.cookware.first
        expect(cookware.name).to eq("bowls")
        expect(cookware.quantity).to eq("several")
      end
    end

    context "with timers" do
      it "parses anonymous timers" do
        recipe = parser.parse("Cook for ~{10%minutes}.")

        expect(recipe.timers.size).to eq(1)
        timer = recipe.timers.first
        expect(timer.name).to be_nil
        expect(timer.duration).to eq(10)
        expect(timer.unit).to eq("minutes")
      end

      it "parses named timers" do
        recipe = parser.parse("Bake ~oven{25%minutes} until golden.")

        expect(recipe.timers.size).to eq(1)
        timer = recipe.timers.first
        expect(timer.name).to eq("oven")
        expect(timer.duration).to eq(25)
        expect(timer.unit).to eq("minutes")
      end

      it "parses timers with decimal durations" do
        recipe = parser.parse("Heat for ~{1.5%hours}.")

        expect(recipe.timers.size).to eq(1)
        timer = recipe.timers.first
        expect(timer.duration).to eq(1.5)
        expect(timer.unit).to eq("hours")
      end
    end

    context "with comments" do
      it "strips line comments" do
        recipe = parser.parse("Add @salt -- this is a comment\nto taste.")

        expect(recipe.steps.size).to eq(1)
        step_text = recipe.steps.first.to_text
        # Comments preserve newlines for canonical compatibility
        expect(step_text).to eq("Add salt \nto taste.")
      end

      it "strips block comments" do
        recipe = parser.parse("Add @salt [- this is a block comment -] to taste.")

        expect(recipe.steps.size).to eq(1)
        step_text = recipe.steps.first.to_text
        expect(step_text).to eq("Add salt  to taste.")
      end
    end

    context "with metadata" do
      it "parses YAML front matter" do
        input = <<~RECIPE
          ---
          title: Pancakes
          servings: 4
          prep_time: 10
          ---

          Mix @flour{1%cup} with @milk{1%cup}.
        RECIPE

        recipe = parser.parse(input)

        expect(recipe.metadata["title"]).to eq("Pancakes")
        expect(recipe.metadata["servings"]).to eq(4)
        expect(recipe.metadata["prep_time"]).to eq(10)
      end

      it "parses inline metadata" do
        input = <<~RECIPE
          >> title: Quick Eggs
          >> servings: 2

          Crack @eggs{2} into #pan.
        RECIPE

        recipe = parser.parse(input)

        expect(recipe.metadata["title"]).to eq("Quick Eggs")
        expect(recipe.metadata["servings"]).to eq(2)
      end
    end

    context "with multiple steps" do
      it "splits steps by blank lines" do
        input = <<~RECIPE
          Mix @flour{1%cup} with @milk{1%cup}.

          Heat #pan over medium heat.

          Pour batter into #pan and cook ~{3%minutes}.
        RECIPE

        recipe = parser.parse(input)

        expect(recipe.steps.size).to eq(3)
        expect(recipe.steps[0].to_text).to eq("Mix flour with milk.")
        expect(recipe.steps[1].to_text).to eq("Heat pan over medium heat.")
        expect(recipe.steps[2].to_text).to eq("Pour batter into pan and cook for 3 minutes.")
      end
    end

    context "with mixed elements" do
      it "parses a complex recipe" do
        input = <<~RECIPE
          ---
          title: Scrambled Eggs
          servings: 2
          ---

          Heat #pan{1} over medium heat.

          Crack @eggs{3} into #bowl and whisk.

          Add @butter{1%tbsp}(melted) to #pan.

          Pour eggs into #pan and cook ~{2-3%minutes}, stirring constantly.
        RECIPE

        recipe = parser.parse(input)

        # Check metadata
        expect(recipe.metadata["title"]).to eq("Scrambled Eggs")
        expect(recipe.metadata["servings"]).to eq(2)

        # Check ingredients
        expect(recipe.ingredients.size).to eq(2)
        eggs = recipe.ingredients.find { |i| i.name == "eggs" }
        expect(eggs.quantity).to eq(3)

        butter = recipe.ingredients.find { |i| i.name == "butter" }
        expect(butter.quantity).to eq(1)
        expect(butter.unit).to eq("tbsp")
        expect(butter.notes).to eq("melted")

        # Check cookware
        expect(recipe.cookware.size).to eq(2)
        pan = recipe.cookware.find { |c| c.name == "pan" }
        expect(pan.quantity).to eq(1)

        bowl = recipe.cookware.find { |c| c.name == "bowl" }
        expect(bowl).not_to be_nil

        # Check timers
        expect(recipe.timers.size).to eq(1)
        timer = recipe.timers.first
        expect(timer.duration).to eq("2-3")
        expect(timer.unit).to eq("minutes")

        # Check steps
        expect(recipe.steps.size).to eq(4)
      end
    end

    context "with edge cases" do
      it "handles empty input" do
        recipe = parser.parse("")

        expect(recipe.ingredients).to be_empty
        expect(recipe.cookware).to be_empty
        expect(recipe.timers).to be_empty
        expect(recipe.steps).to be_empty
        expect(recipe.metadata).to be_empty
      end

      it "handles whitespace-only input" do
        recipe = parser.parse("   \n\n  \n  ")

        expect(recipe.ingredients).to be_empty
        expect(recipe.cookware).to be_empty
        expect(recipe.timers).to be_empty
        expect(recipe.steps).to be_empty
      end

      it "deduplicates identical ingredients" do
        recipe = parser.parse("Add @salt. Then add more @salt.")

        expect(recipe.ingredients.size).to eq(1)
        expect(recipe.ingredients.first.name).to eq("salt")
      end

      it "keeps different quantities as separate ingredients" do
        recipe = parser.parse("Add @salt{1%tsp}. Then add @salt{2%tsp}.")

        expect(recipe.ingredients.size).to eq(2)
        expect(recipe.ingredients.map(&:quantity)).to contain_exactly(1, 2)
      end
    end

    context "with step segments" do
      it "preserves text and ingredient references in steps" do
        recipe = parser.parse("Mix @flour{1%cup} with @milk.")

        step = recipe.steps.first
        expect(step.segments.size).to eq(5)
        expect(step.segments[0]).to eq("Mix ")
        expect(step.segments[1]).to be_a(Cooklang::Ingredient)
        expect(step.segments[2]).to eq(" with ")
        expect(step.segments[3]).to be_a(Cooklang::Ingredient)
        expect(step.segments[4]).to eq(".")
      end

      it "includes cookware and timers in step segments" do
        recipe = parser.parse("Cook in #pan for ~{5%minutes}.")

        step = recipe.steps.first
        expect(step.segments).to include(an_instance_of(Cooklang::Cookware))
        expect(step.segments).to include(an_instance_of(Cooklang::Timer))
      end
    end

    context "with edge cases" do
      it "handles timer with invalid duration format" do
        input = "Cook ~{invalid_duration}"
        recipe = parser.parse(input)

        expect(recipe.timers.size).to eq(1)
        timer = recipe.timers.first
        expect(timer.duration).to eq("invalid_duration")
        expect(timer.unit).to be_nil
      end

      it "handles timer with number-only duration" do
        input = "Cook ~{30}"
        recipe = parser.parse(input)

        expect(recipe.timers.size).to eq(1)
        timer = recipe.timers.first
        expect(timer.duration).to eq(30)
        expect(timer.unit).to be_nil
      end

      it "handles timer with decimal duration" do
        input = "Cook ~{2.5}"
        recipe = parser.parse(input)

        expect(recipe.timers.size).to eq(1)
        timer = recipe.timers.first
        expect(timer.duration).to eq(2.5)
        expect(timer.unit).to be_nil
      end

      it "handles ingredient with invalid quantity format" do
        input = "Add @salt{invalid_amount}"
        recipe = parser.parse(input)

        expect(recipe.ingredients.size).to eq(1)
        ingredient = recipe.ingredients.first
        expect(ingredient.quantity).to eq("invalid_amount")
        expect(ingredient.unit).to be_nil
      end
    end
  end
end
