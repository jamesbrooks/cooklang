# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Metadata do
  describe "#initialize" do
    it "creates empty metadata" do
      metadata = described_class.new

      expect(metadata).to be_empty
    end

    it "creates metadata from hash" do
      data = { "title" => "Test Recipe", "servings" => 4 }
      metadata = described_class.new(data)

      expect(metadata["title"]).to eq("Test Recipe")
      expect(metadata["servings"]).to eq(4)
    end

    it "converts symbol keys to strings" do
      data = { title: "Test Recipe", servings: 4 }
      metadata = described_class.new(data)

      expect(metadata["title"]).to eq("Test Recipe")
      expect(metadata["servings"]).to eq(4)
    end
  end

  describe "hash access methods" do
    let(:metadata) { described_class.new(title: "Test Recipe", servings: 4) }

    describe "#[]=" do
      it "converts keys to strings" do
        metadata[:prep_time] = "10 minutes"

        expect(metadata["prep_time"]).to eq("10 minutes")
      end
    end

    describe "#[]" do
      it "converts keys to strings" do
        expect(metadata[:title]).to eq("Test Recipe")
        expect(metadata["title"]).to eq("Test Recipe")
      end
    end

    describe "#key?" do
      it "converts keys to strings" do
        expect(metadata.key?(:title)).to be true
        expect(metadata.key?("title")).to be true
        expect(metadata.key?(:nonexistent)).to be false
      end
    end

    describe "#delete" do
      it "converts keys to strings" do
        metadata.delete(:title)

        expect(metadata).not_to have_key("title")
      end
    end

    describe "#fetch" do
      it "converts keys to strings" do
        expect(metadata.fetch(:title)).to eq("Test Recipe")
        expect(metadata.fetch(:nonexistent, "default")).to eq("default")
      end
    end
  end

  describe "#to_h" do
    it "returns plain hash" do
      metadata = described_class.new(title: "Test Recipe", servings: 4)

      hash = metadata.to_h

      expect(hash).to be_a(Hash)
      expect(hash).not_to be_a(described_class)
      expect(hash).to eq({ "title" => "Test Recipe", "servings" => 4 })
    end
  end

  describe "recipe-specific accessors" do
    let(:metadata) { described_class.new }

    describe "#servings" do
      it "returns integer servings" do
        metadata["servings"] = "4"

        expect(metadata.servings).to eq(4)
      end

      it "returns nil when not set" do
        expect(metadata.servings).to be_nil
      end
    end

    describe "#servings=" do
      it "sets servings" do
        metadata.servings = 6

        expect(metadata["servings"]).to eq(6)
      end
    end

    describe "#prep_time" do
      it "returns prep_time" do
        metadata["prep_time"] = "15 minutes"

        expect(metadata.prep_time).to eq("15 minutes")
      end

      it "returns prep-time as fallback" do
        metadata["prep-time"] = "15 minutes"

        expect(metadata.prep_time).to eq("15 minutes")
      end

      it "returns nil when not set" do
        expect(metadata.prep_time).to be_nil
      end
    end

    describe "#prep_time=" do
      it "sets prep_time" do
        metadata.prep_time = "20 minutes"

        expect(metadata["prep_time"]).to eq("20 minutes")
      end
    end

    describe "#cook_time" do
      it "returns cook_time" do
        metadata["cook_time"] = "30 minutes"

        expect(metadata.cook_time).to eq("30 minutes")
      end

      it "returns cook-time as fallback" do
        metadata["cook-time"] = "30 minutes"

        expect(metadata.cook_time).to eq("30 minutes")
      end
    end

    describe "#cook_time=" do
      it "sets cook_time" do
        metadata.cook_time = "25 minutes"

        expect(metadata["cook_time"]).to eq("25 minutes")
      end
    end

    describe "#total_time" do
      it "returns total_time" do
        metadata["total_time"] = "45 minutes"

        expect(metadata.total_time).to eq("45 minutes")
      end

      it "returns total-time as fallback" do
        metadata["total-time"] = "45 minutes"

        expect(metadata.total_time).to eq("45 minutes")
      end
    end

    describe "#total_time=" do
      it "sets total_time" do
        metadata.total_time = "50 minutes"

        expect(metadata["total_time"]).to eq("50 minutes")
      end
    end

    describe "#title" do
      it "returns title" do
        metadata["title"] = "Chocolate Cake"

        expect(metadata.title).to eq("Chocolate Cake")
      end
    end

    describe "#title=" do
      it "sets title" do
        metadata.title = "Vanilla Cake"

        expect(metadata["title"]).to eq("Vanilla Cake")
      end
    end

    describe "#source" do
      it "returns source" do
        metadata["source"] = "cookbook.com"

        expect(metadata.source).to eq("cookbook.com")
      end
    end

    describe "#source=" do
      it "sets source" do
        metadata.source = "my-blog.com"

        expect(metadata["source"]).to eq("my-blog.com")
      end
    end

    describe "#tags" do
      it "returns array when tags is array" do
        metadata["tags"] = ["dessert", "chocolate"]

        expect(metadata.tags).to eq(["dessert", "chocolate"])
      end

      it "splits string tags on comma" do
        metadata["tags"] = "dessert, chocolate, sweet"

        expect(metadata.tags).to eq(["dessert", "chocolate", "sweet"])
      end

      it "returns empty array when not set" do
        expect(metadata.tags).to eq([])
      end

      it "returns empty array for non-string, non-array values" do
        metadata["tags"] = 123

        expect(metadata.tags).to eq([])
      end
    end

    describe "#tags=" do
      it "sets tags" do
        metadata.tags = ["breakfast", "quick"]

        expect(metadata["tags"]).to eq(["breakfast", "quick"])
      end
    end
  end
end
