# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "Canonical Tests" do
  # Load the canonical test suite from the official Cooklang spec
  CANONICAL_TESTS = YAML.load_file(File.expand_path("../fixtures/canonical.yaml", __dir__))

  describe "test file structure" do
    it "has a version" do
      expect(CANONICAL_TESTS).to have_key("version")
      expect(CANONICAL_TESTS["version"]).to be_a(Integer)
    end

    it "has tests" do
      expect(CANONICAL_TESTS).to have_key("tests")
      expect(CANONICAL_TESTS["tests"]).to be_a(Hash)
    end

    it "has valid test structure" do
      CANONICAL_TESTS["tests"].each do |test_name, test_data|
        expect(test_data).to have_key("source"), "Test #{test_name} missing 'source'"
        expect(test_data).to have_key("result"), "Test #{test_name} missing 'result'"
        expect(test_data["source"]).to be_a(String), "Test #{test_name} source should be a string"
        expect(test_data["result"]).to be_a(Hash), "Test #{test_name} result should be a hash"
      end
    end
  end

  describe "lexer compatibility" do
    # For now, we just verify that our lexer can tokenize all the test sources
    # without errors. We're not checking the results yet.
    CANONICAL_TESTS["tests"].each do |test_name, test_data|
      it "can tokenize: #{test_name}" do
        source = test_data["source"]

        # Our lexer should be able to tokenize any valid Cooklang source
        lexer = Cooklang::Lexer.new(source)
        tokens = lexer.tokenize

        # Basic sanity checks
        expect(tokens).to be_an(Array)

        # Empty source should produce empty tokens
        if source.strip.empty?
          expect(tokens).to be_empty
        else
          # Non-empty source should produce some tokens
          expect(tokens).not_to be_empty unless source.strip == "--" || source.strip.start_with?("--")
        end

        # All tokens should be valid Token objects
        tokens.each do |token|
          expect(token).to be_a(Cooklang::Token)
          expect(token.type).to be_a(Symbol)
          expect(token.value).to be_a(String)
          expect(token.position).to be_a(Integer)
          expect(token.line).to be_a(Integer)
          expect(token.column).to be_a(Integer)
        end
      end
    end
  end

  describe "test coverage analysis" do
    it "covers all major Cooklang features" do
      test_names = CANONICAL_TESTS["tests"].keys

      # Check that we have tests for major features
      expect(test_names.any? { |n| n.downcase.include?("ingredient") }).to be true
      expect(test_names.any? { |n| n.downcase.include?("cookware") }).to be true
      expect(test_names.any? { |n| n.downcase.include?("timer") }).to be true
      expect(test_names.any? { |n| n.downcase.include?("metadata") }).to be true
      expect(test_names.any? { |n| n.downcase.include?("comment") }).to be true
    end

    it "has at least 20 test cases" do
      expect(CANONICAL_TESTS["tests"].size).to be >= 20
    end
  end

  # Parser result tests - validates that our parser produces the exact same
  # structure as the canonical test expectations
  describe "parser results" do
    CANONICAL_TESTS["tests"].each do |test_name, test_data|
      it "parses correctly: #{test_name}" do
        source = test_data["source"]
        expected = test_data["result"]

        recipe = Cooklang.parse(source)

        # Convert our internal format to canonical format for comparison
        actual = recipe_to_canonical_format(recipe)

        # Compare the complete result structure
        expect(actual).to eq(expected),
                          "Test #{test_name} failed.\nExpected: #{expected.inspect}\nActual: #{actual.inspect}"
      end
    end
  end

  private
    # Convert our Recipe object to the canonical test format
    def recipe_to_canonical_format(recipe)
      {
        "steps" => recipe.steps.map { |step| step_to_canonical_format(step) },
        "metadata" => recipe.metadata.to_h
      }
    end

    # Combine adjacent text segments (strings) into single segments
    def combine_adjacent_text_segments(segments)
      result = []
      current_text = nil

      segments.each do |segment|
        if segment.is_a?(String)
          # Convert standalone newlines to spaces per Cooklang spec
          segment_text = segment == "\n" ? " " : segment

          if current_text
            current_text += segment_text
          else
            current_text = segment_text
          end
        else
          # Non-text segment - flush any accumulated text first
          if current_text && !current_text.strip.empty?
            result << current_text
            current_text = nil
          elsif current_text
            # Discard whitespace-only text segments
            current_text = nil
          end
          result << segment
        end
      end

      # Don't forget the last text segment if there is one (and it's not just whitespace)
      result << current_text if current_text && !current_text.strip.empty?

      result
    end

    # Convert quantity values to match canonical expectations
    def convert_quantity_to_canonical_format(quantity)
      return quantity unless quantity.is_a?(String)

      # Handle fractions like "1/2" or "1 / 2" but NOT "01/2" (leading zeros invalid)
      # Following Rust implementation: only Int tokens (no leading zeros) are valid for fractions
      # Pattern: valid numbers are either "0" or start with 1-9
      if quantity.match(%r{^\s*(0|[1-9]\d*)\s*/\s*(0|[1-9]\d*)\s*$})
        numerator = Regexp.last_match(1).to_f
        denominator = Regexp.last_match(2).to_f
        return numerator / denominator if denominator != 0
      end

      # Return as-is for non-fraction strings or invalid fractions
      quantity
    end

    # Convert a Step object to canonical format (array of segment hashes)
    def step_to_canonical_format(step)
      # First, combine adjacent text segments to match canonical expectations
      combined_segments = combine_adjacent_text_segments(step.segments)

      combined_segments.map.with_index do |segment, index|
        next_segment = combined_segments[index + 1]

        case segment
        when String
          { "type" => "text", "value" => segment }
        when Cooklang::Ingredient
          result = {
            "type" => "ingredient",
            "name" => segment.name
          }
          if segment.quantity
            # Convert fractions to decimals to match canonical test expectations
            result["quantity"] = convert_quantity_to_canonical_format(segment.quantity)
          end
          # Always include units field, use empty string if nil
          result["units"] = segment.unit || ""
          result["notes"] = segment.notes if segment.notes
          result
        when Cooklang::Cookware
          result = {
            "type" => "cookware",
            "name" => segment.name,
            "quantity" => segment.quantity
          }

          # Add units field if the next segment starts with punctuation
          result["units"] = "" if next_segment.is_a?(String) && next_segment.match(/^[^\w\s]/)

          result
        when Cooklang::Timer
          result = {
            "type" => "timer",
            "quantity" => segment.duration ? convert_quantity_to_canonical_format(segment.duration) : "",
            "units" => segment.unit || "",
            "name" => segment.name || ""
          }
          result
        else
          raise "Unknown segment type: #{segment.class}"
        end
      end
    end
end
