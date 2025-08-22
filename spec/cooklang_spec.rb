# frozen_string_literal: true

RSpec.describe Cooklang do
  it "has a version number" do
    expect(Cooklang::VERSION).not_to be nil
  end

  describe ".parse" do
    it "returns a Recipe object" do
      recipe = Cooklang.parse("")

      expect(recipe).to be_a(Cooklang::Recipe)
    end

    it "returns recipe with empty collections for empty input" do
      recipe = Cooklang.parse("")

      expect(recipe.ingredients).to be_empty
      expect(recipe.cookware).to be_empty
      expect(recipe.timers).to be_empty
      expect(recipe.steps).to be_empty
      expect(recipe.metadata).to be_a(Cooklang::Metadata)
    end
  end

  describe ".parse_file" do
    it "reads and parses a file" do
      allow(File).to receive(:read).with("recipe.cook").and_return("test content")
      allow(Cooklang).to receive(:parse).with("test content").and_return("parsed result")

      result = Cooklang.parse_file("recipe.cook")

      expect(result).to eq("parsed result")
    end
  end
end
