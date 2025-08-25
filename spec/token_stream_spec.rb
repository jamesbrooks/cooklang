# frozen_string_literal: true

require "spec_helper"
require "cooklang/token_stream"
require "cooklang/lexer"

RSpec.describe Cooklang::TokenStream do
  let(:tokens) do
    [
      Cooklang::Token.new(:text, "hello", 0, 0, 0),
      Cooklang::Token.new(:ingredient_marker, "@", 0, 5, 5),
      Cooklang::Token.new(:text, "salt", 0, 6, 6),
      Cooklang::Token.new(:open_brace, "{", 0, 10, 10),
      Cooklang::Token.new(:text, "2%g", 0, 11, 11),
      Cooklang::Token.new(:close_brace, "}", 0, 14, 14),
      Cooklang::Token.new(:newline, "\n", 0, 15, 15)
    ]
  end

  let(:stream) { described_class.new(tokens) }

  describe "#initialize" do
    it "sets up the token array and position" do
      expect(stream.position).to eq(0)
      expect(stream.size).to eq(7)
      expect(stream.length).to eq(7)
    end
  end

  describe "#current" do
    it "returns the current token" do
      expect(stream.current.type).to eq(:text)
      expect(stream.current.value).to eq("hello")
    end

    it "returns nil when at EOF" do
      empty_stream = described_class.new([])
      expect(empty_stream.current).to be_nil
    end
  end

  describe "#peek" do
    it "returns the next token without advancing" do
      expect(stream.peek.type).to eq(:ingredient_marker)
      expect(stream.position).to eq(0)
    end

    it "accepts an offset parameter" do
      expect(stream.peek(2).type).to eq(:text)
      expect(stream.peek(2).value).to eq("salt")
    end

    it "returns nil when peeking beyond EOF" do
      expect(stream.peek(10)).to be_nil
    end
  end

  describe "#consume" do
    it "returns current token and advances position" do
      token = stream.consume
      expect(token.type).to eq(:text)
      expect(token.value).to eq("hello")
      expect(stream.position).to eq(1)
    end

    it "accepts expected type parameter" do
      token = stream.consume(:text)
      expect(token.type).to eq(:text)
      expect(stream.position).to eq(1)
    end

    it "returns nil when expected type does not match" do
      token = stream.consume(:ingredient_marker)
      expect(token).to be_nil
      expect(stream.position).to eq(0)
    end

    it "returns nil at EOF" do
      empty_stream = described_class.new([])
      expect(empty_stream.consume).to be_nil
    end
  end

  describe "#eof?" do
    it "returns false when tokens remain" do
      expect(stream.eof?).to be_falsey
    end

    it "returns true when at end" do
      stream.advance_to(7)
      expect(stream.eof?).to be_truthy
    end
  end

  describe "#scan" do
    it "consumes token when type matches" do
      token = stream.scan(:text)
      expect(token.value).to eq("hello")
      expect(stream.position).to eq(1)
    end

    it "returns nil when type does not match" do
      token = stream.scan(:ingredient_marker)
      expect(token).to be_nil
      expect(stream.position).to eq(0)
    end
  end

  describe "#check" do
    it "returns true when current token type matches" do
      expect(stream.check(:text)).to be_truthy
    end

    it "returns false when current token type does not match" do
      expect(stream.check(:ingredient_marker)).to be_falsey
    end
  end

  describe "#skip" do
    it "advances position when type matches" do
      stream.skip(:text)
      expect(stream.position).to eq(1)
    end

    it "does not advance when type does not match" do
      stream.skip(:ingredient_marker)
      expect(stream.position).to eq(0)
    end
  end

  describe "#consume_while" do
    it "consumes tokens while condition is true" do
      stream.consume # Move to ingredient marker
      tokens_consumed = stream.consume_while { |token| token.type != :open_brace }

      expect(tokens_consumed.length).to eq(2)
      expect(tokens_consumed[0].type).to eq(:ingredient_marker)
      expect(tokens_consumed[1].type).to eq(:text)
      expect(stream.current.type).to eq(:open_brace)
    end
  end

  describe "#consume_until" do
    it "consumes tokens until condition is true" do
      tokens_consumed = stream.consume_until { |token| token.type == :open_brace }

      expect(tokens_consumed.length).to eq(3)
      expect(stream.current.type).to eq(:open_brace)
    end
  end

  describe "#find_next" do
    it "finds the index of the next matching token type" do
      index = stream.find_next(:open_brace)
      expect(index).to eq(3)
    end

    it "returns nil when token type not found" do
      index = stream.find_next(:hyphen)
      expect(index).to be_nil
    end
  end

  describe "#find_next_matching" do
    it "finds the index of the next token matching a block condition" do
      index = stream.find_next_matching { |token| token.value.include?("g") }
      expect(index).to eq(4)
    end
  end

  describe "#rest" do
    it "returns remaining tokens from current position" do
      stream.consume # Move to ingredient marker
      remaining = stream.rest
      expect(remaining.length).to eq(6)
      expect(remaining[0].type).to eq(:ingredient_marker)
    end
  end

  describe "#reset" do
    it "resets position to beginning" do
      stream.consume
      stream.consume
      stream.reset
      expect(stream.position).to eq(0)
      expect(stream.current.type).to eq(:text)
    end
  end

  describe "#rewind" do
    it "moves position back by specified steps" do
      stream.consume
      stream.consume
      stream.consume
      expect(stream.position).to eq(3)

      stream.rewind(2)
      expect(stream.position).to eq(1)
    end

    it "does not go below 0" do
      stream.consume
      stream.rewind(5)
      expect(stream.position).to eq(0)
    end
  end

  describe "Enumerable methods" do
    it "supports map" do
      types = stream.map(&:type)
      expect(types).to eq([:text, :ingredient_marker, :text, :open_brace, :text, :close_brace, :newline])
    end

    it "supports find" do
      ingredient_token = stream.find { |token| token.type == :ingredient_marker }
      expect(ingredient_token.type).to eq(:ingredient_marker)
    end

    it "supports any?" do
      expect(stream.any? { |token| token.type == :open_brace }).to be_truthy
    end

    it "supports select" do
      text_tokens = stream.select { |token| token.type == :text }
      expect(text_tokens.length).to eq(3)
    end
  end

  describe "#each_with_lookahead" do
    it "yields current and next token pairs" do
      pairs = []
      stream.each_with_lookahead { |current, next_token| pairs << [current.type, next_token.type] }

      expect(pairs).to eq([
        [:text, :ingredient_marker],
        [:ingredient_marker, :text],
        [:text, :open_brace],
        [:open_brace, :text],
        [:text, :close_brace],
        [:close_brace, :newline]
      ])
    end
  end

  describe "#slice_from_current" do
    it "creates a new stream from current position" do
      stream.consume
      stream.consume
      new_stream = stream.slice_from_current

      expect(new_stream.current.type).to eq(:text)
      expect(new_stream.current.value).to eq("salt")
      expect(new_stream.size).to eq(5)
    end
  end

  describe "#skip_whitespace" do
    let(:tokens_with_whitespace) do
      [
        Cooklang::Token.new(:text, "start", 0, 1, 1),
        Cooklang::Token.new(:whitespace, " ", 1, 1, 2),
        Cooklang::Token.new(:whitespace, "\t", 2, 1, 3),
        Cooklang::Token.new(:text, "end", 3, 1, 4)
      ]
    end

    it "consumes whitespace tokens" do
      stream = described_class.new(tokens_with_whitespace)
      stream.consume # Move past "start"

      expect(stream.current.type).to eq(:whitespace)
      stream.skip_whitespace

      expect(stream.current.type).to eq(:text)
      expect(stream.current.value).to eq("end")
    end
  end
end
