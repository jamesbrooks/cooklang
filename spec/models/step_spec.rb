# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Step do
  describe "#initialize" do
    it "creates step with segments" do
      segments = ["Mix the ", { type: :ingredient, name: "flour" }, " and ", { type: :ingredient, name: "salt" }]
      step = described_class.new(segments: segments)

      expect(step.segments).to eq(segments)
      expect(step.segments).to be_frozen
    end
  end

  describe "#to_text" do
    it "converts mixed segments to plain text" do
      segments = [
        "Mix the ",
        { type: :ingredient, name: "flour" },
        " with ",
        { type: :cookware, name: "spoon" },
        " for ",
        { type: :timer, name: "mixing" }
      ]
      step = described_class.new(segments: segments)

      expect(step.to_text).to eq("Mix the flour with spoon for mixing")
    end

    it "handles timer without name" do
      segments = ["Cook for ", { type: :timer, duration: 5, unit: "minutes" }]
      step = described_class.new(segments: segments)

      expect(step.to_text).to eq("Cook for timer")
    end

    it "handles string segments" do
      segments = ["Just plain text"]
      step = described_class.new(segments: segments)

      expect(step.to_text).to eq("Just plain text")
    end

    it "handles unknown segment types" do
      segments = ["Text", { type: :unknown, value: "something" }]
      step = described_class.new(segments: segments)

      expect(step.to_text).to eq("Textsomething")
    end

    it "handles segments without value" do
      segments = ["Text", { type: :unknown }]
      step = described_class.new(segments: segments)

      expect(step.to_text).to eq("Text")
    end

    it "handles non-hash, non-string segments" do
      segments = ["Text", 123]
      step = described_class.new(segments: segments)

      expect(step.to_text).to eq("Text123")
    end
  end

  describe "#to_h" do
    it "returns hash representation" do
      segments = ["Mix ", { type: :ingredient, name: "flour" }]
      step = described_class.new(segments: segments)

      expect(step.to_h).to eq({ segments: segments })
    end
  end

  describe "#==" do
    it "returns true for steps with same segments" do
      segments = ["Mix ", { type: :ingredient, name: "flour" }]
      step1 = described_class.new(segments: segments)
      step2 = described_class.new(segments: segments)

      expect(step1).to eq(step2)
    end

    it "returns false for steps with different segments" do
      step1 = described_class.new(segments: ["Mix flour"])
      step2 = described_class.new(segments: ["Mix salt"])

      expect(step1).not_to eq(step2)
    end

    it "returns false for non-Step objects" do
      step = described_class.new(segments: ["Mix flour"])

      expect(step).not_to eq("Mix flour")
    end
  end

  describe "#ingredients_used" do
    it "returns names of ingredients used in step" do
      segments = [
        "Mix ",
        { type: :ingredient, name: "flour" },
        " and ",
        { type: :ingredient, name: "salt" },
        " with ",
        { type: :cookware, name: "spoon" }
      ]
      step = described_class.new(segments: segments)

      expect(step.ingredients_used).to eq(["flour", "salt"])
    end

    it "returns empty array when no ingredients" do
      segments = ["Just mix with ", { type: :cookware, name: "spoon" }]
      step = described_class.new(segments: segments)

      expect(step.ingredients_used).to eq([])
    end
  end

  describe "#cookware_used" do
    it "returns names of cookware used in step" do
      segments = [
        "Mix with ",
        { type: :cookware, name: "spoon" },
        " in ",
        { type: :cookware, name: "bowl" },
        " using ",
        { type: :ingredient, name: "flour" }
      ]
      step = described_class.new(segments: segments)

      expect(step.cookware_used).to eq(["spoon", "bowl"])
    end

    it "returns empty array when no cookware" do
      segments = ["Mix ", { type: :ingredient, name: "flour" }]
      step = described_class.new(segments: segments)

      expect(step.cookware_used).to eq([])
    end
  end

  describe "#timers_used" do
    it "returns timer segments used in step" do
      timer1 = { type: :timer, name: "mixing", duration: 2, unit: "minutes" }
      timer2 = { type: :timer, duration: 5, unit: "minutes" }
      segments = [
        "Mix for ",
        timer1,
        " then wait ",
        timer2,
        " using ",
        { type: :ingredient, name: "flour" }
      ]
      step = described_class.new(segments: segments)

      expect(step.timers_used).to eq([timer1, timer2])
    end

    it "returns empty array when no timers" do
      segments = ["Mix ", { type: :ingredient, name: "flour" }]
      step = described_class.new(segments: segments)

      expect(step.timers_used).to eq([])
    end
  end

  describe "predicate methods" do
    describe "#has_ingredients?" do
      it "returns true when step contains ingredients" do
        segments = ["Mix ", { type: :ingredient, name: "flour" }]
        step = described_class.new(segments: segments)

        expect(step).to have_ingredients
      end

      it "returns false when step has no ingredients" do
        segments = ["Just text"]
        step = described_class.new(segments: segments)

        expect(step).not_to have_ingredients
      end
    end

    describe "#has_cookware?" do
      it "returns true when step contains cookware" do
        segments = ["Use ", { type: :cookware, name: "spoon" }]
        step = described_class.new(segments: segments)

        expect(step).to have_cookware
      end

      it "returns false when step has no cookware" do
        segments = ["Just text"]
        step = described_class.new(segments: segments)

        expect(step).not_to have_cookware
      end
    end

    describe "#has_timers?" do
      it "returns true when step contains timers" do
        segments = ["Wait ", { type: :timer, duration: 5, unit: "minutes" }]
        step = described_class.new(segments: segments)

        expect(step).to have_timers
      end

      it "returns false when step has no timers" do
        segments = ["Just text"]
        step = described_class.new(segments: segments)

        expect(step).not_to have_timers
      end
    end
  end

  describe "#hash" do
    it "generates same hash for equal steps" do
      segments = ["Mix ", { type: :ingredient, name: "flour" }]
      step1 = described_class.new(segments: segments)
      step2 = described_class.new(segments: segments)

      expect(step1.hash).to eq(step2.hash)
    end

    it "generates different hash for different steps" do
      step1 = described_class.new(segments: ["Mix flour"])
      step2 = described_class.new(segments: ["Mix salt"])

      expect(step1.hash).not_to eq(step2.hash)
    end
  end
end
