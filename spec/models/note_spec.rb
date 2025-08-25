# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Note do
  describe "#initialize" do
    it "creates note with content" do
      note = described_class.new(content: "This is a note")
      expect(note.content).to eq("This is a note")
    end

    it "converts content to string and freezes it" do
      note = described_class.new(content: 123)
      expect(note.content).to eq("123")
      expect(note.content).to be_frozen
    end
  end

  describe "#to_s" do
    it "returns content" do
      note = described_class.new(content: "Test note")
      expect(note.to_s).to eq("Test note")
    end
  end

  describe "#to_h" do
    it "returns hash representation" do
      note = described_class.new(content: "Test note")
      expect(note.to_h).to eq({ content: "Test note" })
    end
  end

  describe "#==" do
    it "returns true for notes with same content" do
      note1 = described_class.new(content: "Same content")
      note2 = described_class.new(content: "Same content")
      expect(note1 == note2).to be_truthy
    end

    it "returns false for notes with different content" do
      note1 = described_class.new(content: "Content 1")
      note2 = described_class.new(content: "Content 2")
      expect(note1 == note2).to be_falsey
    end

    it "returns false for non-Note objects" do
      note = described_class.new(content: "Test")
      expect(note == "Test").to be_falsey
    end
  end

  describe "#hash" do
    it "generates same hash for equal notes" do
      note1 = described_class.new(content: "Test")
      note2 = described_class.new(content: "Test")
      expect(note1.hash).to eq(note2.hash)
    end

    it "generates different hash for different notes" do
      note1 = described_class.new(content: "Test 1")
      note2 = described_class.new(content: "Test 2")
      expect(note1.hash).not_to eq(note2.hash)
    end
  end
end
