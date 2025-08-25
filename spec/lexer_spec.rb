# frozen_string_literal: true

require "spec_helper"

RSpec.describe Cooklang::Lexer do
  describe "#tokenize" do
    context "with empty input" do
      it "returns empty array" do
        lexer = described_class.new("")
        tokens = lexer.tokenize
        expect(tokens).to be_empty
      end
    end

    context "with plain text" do
      it "tokenizes simple text" do
        lexer = described_class.new("Hello world")
        tokens = lexer.tokenize

        expect(tokens.length).to eq(1)
        expect(tokens[0].type).to eq(:text)
        expect(tokens[0].value).to eq("Hello world")
      end

      it "handles text with spaces" do
        lexer = described_class.new("Mix the ingredients well")
        tokens = lexer.tokenize

        expect(tokens.length).to eq(1)
        expect(tokens[0].type).to eq(:text)
        expect(tokens[0].value).to eq("Mix the ingredients well")
      end
    end

    context "with ingredient markers" do
      it "tokenizes simple ingredient" do
        lexer = described_class.new("@salt")
        tokens = lexer.tokenize

        expect(tokens.length).to eq(2)
        expect(tokens[0].type).to eq(:ingredient_marker)
        expect(tokens[0].value).to eq("@")
        expect(tokens[1].type).to eq(:text)
        expect(tokens[1].value).to eq("salt")
      end

      it "tokenizes ingredient with braces" do
        lexer = described_class.new("@flour{125%g}")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[
                                           ingredient_marker text open_brace text percent text close_brace
                                         ])
        expect(tokens.map(&:value)).to eq(["@", "flour", "{", "125", "%", "g", "}"])
      end

      it "tokenizes ingredient with parentheses" do
        lexer = described_class.new("@onion(diced)")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[
                                           ingredient_marker text open_paren text close_paren
                                         ])
        expect(tokens.map(&:value)).to eq(["@", "onion", "(", "diced", ")"])
      end
    end

    context "with cookware markers" do
      it "tokenizes simple cookware" do
        lexer = described_class.new("#pan")
        tokens = lexer.tokenize

        expect(tokens.length).to eq(2)
        expect(tokens[0].type).to eq(:cookware_marker)
        expect(tokens[0].value).to eq("#")
        expect(tokens[1].type).to eq(:text)
        expect(tokens[1].value).to eq("pan")
      end

      it "tokenizes cookware with braces" do
        lexer = described_class.new("#frying pan{1}")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[
                                           cookware_marker text open_brace text close_brace
                                         ])
        expect(tokens.map(&:value)).to eq(["#", "frying pan", "{", "1", "}"])
      end
    end

    context "with timer markers" do
      it "tokenizes simple timer" do
        lexer = described_class.new("~{10%minutes}")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[
                                           timer_marker open_brace text percent text close_brace
                                         ])
        expect(tokens.map(&:value)).to eq(["~", "{", "10", "%", "minutes", "}"])
      end

      it "tokenizes named timer" do
        lexer = described_class.new("~prep{5%minutes}")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[
                                           timer_marker text open_brace text percent text close_brace
                                         ])
        expect(tokens.map(&:value)).to eq(["~", "prep", "{", "5", "%", "minutes", "}"])
      end
    end

    context "with comments" do
      it "tokenizes line comments" do
        lexer = described_class.new("-- This is a comment")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[comment_line text])
        expect(tokens.map(&:value)).to eq(["--", " This is a comment"])
      end

      it "tokenizes block comments" do
        lexer = described_class.new("[- This is a block comment -]")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[comment_block_start text comment_block_end])
        expect(tokens.map(&:value)).to eq(["[-", " This is a block comment ", "-]"])
      end

      it "handles incomplete block comments" do
        lexer = described_class.new("[- Incomplete comment")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[comment_block_start text])
        expect(tokens.map(&:value)).to eq(["[-", " Incomplete comment"])
      end
    end

    context "with metadata markers" do
      it "tokenizes metadata marker" do
        lexer = described_class.new(">> servings: 4")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[metadata_marker text])
        expect(tokens.map(&:value)).to eq([">>", " servings: 4"])
      end
    end

    context "with section markers" do
      it "tokenizes single equals" do
        lexer = described_class.new("= Dough")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[section_marker text])
        expect(tokens.map(&:value)).to eq(["=", " Dough"])
      end

      it "tokenizes double equals" do
        lexer = described_class.new("== Filling ==")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[section_marker text section_marker])
        expect(tokens.map(&:value)).to eq(["==", " Filling ", "=="])
      end

      it "tokenizes multiple equals" do
        lexer = described_class.new("=== Section ===")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[section_marker text section_marker])
        expect(tokens.map(&:value)).to eq(["===", " Section ", "==="])
      end
    end

    context "with note markers" do
      it "tokenizes note marker" do
        lexer = described_class.new("> Don't burn the roux!")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[note_marker text])
        expect(tokens.map(&:value)).to eq([">", " Don't burn the roux!"])
      end

      it "does not tokenize > in metadata marker >>" do
        lexer = described_class.new(">> servings: 4")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[metadata_marker text])
        expect(tokens.map(&:value)).to eq([">>", " servings: 4"])
      end
    end

    context "with YAML delimiters" do
      it "tokenizes YAML delimiter" do
        lexer = described_class.new("---")
        tokens = lexer.tokenize

        expect(tokens.length).to eq(1)
        expect(tokens[0].type).to eq(:yaml_delimiter)
        expect(tokens[0].value).to eq("---")
      end
    end

    context "with newlines" do
      it "tokenizes newlines" do
        lexer = described_class.new("Line 1\nLine 2")
        tokens = lexer.tokenize

        expect(tokens.map(&:type)).to eq(%i[text newline text])
        expect(tokens.map(&:value)).to eq(["Line 1", "\n", "Line 2"])
      end

      it "tracks line numbers correctly" do
        lexer = described_class.new("Line 1\nLine 2\nLine 3")
        tokens = lexer.tokenize

        expect(tokens[0].line).to eq(1)  # "Line 1"
        expect(tokens[1].line).to eq(1)  # "\n"
        expect(tokens[2].line).to eq(2)  # "Line 2"
        expect(tokens[3].line).to eq(2)  # "\n"
        expect(tokens[4].line).to eq(3)  # "Line 3"
      end
    end

    context "with complex recipes" do
      it "tokenizes a complete recipe step" do
        input = "Mix @flour{125%g} with @milk{250%ml} in a #bowl{1}."
        lexer = described_class.new(input)
        tokens = lexer.tokenize

        expected_types = %i[
          text ingredient_marker text open_brace text percent text close_brace
          text ingredient_marker text open_brace text percent text close_brace
          text cookware_marker text open_brace text close_brace text
        ]

        expect(tokens.map(&:type)).to eq(expected_types)
      end

      it "tokenizes recipe with timer and comments" do
        input = "Cook for ~{10%minutes} -- until golden\nServe hot"
        lexer = described_class.new(input)
        tokens = lexer.tokenize

        expected_values = [
          "Cook for ", "~", "{", "10", "%", "minutes", "}", " ",
          "--", " until golden", "\n", "Serve hot"
        ]

        expect(tokens.map(&:value)).to eq(expected_values)
      end
    end

    context "with position tracking" do
      it "tracks position correctly" do
        lexer = described_class.new("@salt")
        tokens = lexer.tokenize

        expect(tokens[0].position).to eq(0)  # '@' at position 0
        expect(tokens[1].position).to eq(1)  # 'salt' at position 1
      end

      it "tracks column numbers correctly" do
        lexer = described_class.new("@salt #pan")
        tokens = lexer.tokenize

        expect(tokens[0].column).to eq(1)  # '@'
        expect(tokens[1].column).to eq(2)  # 'salt '
        expect(tokens[2].column).to eq(7)  # '#'
        expect(tokens[3].column).to eq(8)  # 'pan'
      end
    end

    context "with edge cases" do
      it "handles consecutive special characters" do
        lexer = described_class.new("@#~{}()")
        tokens = lexer.tokenize

        expected_types = %i[
          ingredient_marker cookware_marker timer_marker
          open_brace close_brace open_paren close_paren
        ]

        expect(tokens.map(&:type)).to eq(expected_types)
      end

      it "handles text between special characters" do
        lexer = described_class.new("Heat @oil in #pan for ~{2%min}")
        tokens = lexer.tokenize

        expect(tokens.filter_map { |t| t.value if t.type == :text }).to eq([
                                                                           "Heat ", "oil in ", "pan for ", "2", "min"
                                                                         ])
      end

      it "handles empty braces and parentheses" do
        lexer = described_class.new("@ingredient{} #cookware() ~timer{}")
        tokens = lexer.tokenize

        ingredient_tokens = tokens[0..3]
        expect(ingredient_tokens.map(&:type)).to eq(%i[
                                                      ingredient_marker text open_brace close_brace
                                                    ])
      end
    end

    context "with whitespace handling" do
      it "preserves whitespace in text" do
        lexer = described_class.new("  Mix   well  ")
        tokens = lexer.tokenize

        expect(tokens.length).to eq(1)
        expect(tokens[0].value).to eq("  Mix   well  ")
      end

      it "handles tabs and spaces" do
        lexer = described_class.new("\tMix @salt  ")
        tokens = lexer.tokenize

        expect(tokens[0].value).to eq("\tMix ")
        expect(tokens[2].value).to eq("salt  ")
      end
    end

    context "with unrecognized characters" do
      it "handles unrecognized characters gracefully" do
        # Test the else branch in tokenize that handles unrecognized characters
        lexer = described_class.new("Mix \x01\x02 salt")
        tokens = lexer.tokenize

        # Should skip unrecognized characters and continue tokenizing
        expect(tokens.map(&:type)).to eq(%i[text text])
        expect(tokens.map(&:value)).to eq(["Mix ", " salt"])
      end
    end
  end

  describe "Token" do
    it "creates token with all attributes" do
      token = Cooklang::Token.new(:text, "hello", 5, 2, 10)

      expect(token.type).to eq(:text)
      expect(token.value).to eq("hello")
      expect(token.position).to eq(5)
      expect(token.line).to eq(2)
      expect(token.column).to eq(10)
    end

    it "creates token with default position values" do
      token = Cooklang::Token.new(:text, "hello")

      expect(token.position).to eq(0)
      expect(token.line).to eq(1)
      expect(token.column).to eq(1)
    end
  end
end
