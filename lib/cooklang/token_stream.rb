# frozen_string_literal: true

require "forwardable"

module Cooklang
  class TokenStream
    include Enumerable
    extend Forwardable

    # Delegate array-like methods to @tokens
    def_delegators :@tokens, :size, :length, :empty?

    attr_reader :position

    def initialize(tokens)
      @tokens = tokens
      @position = 0
    end

    def current
      @tokens[@position]
    end

    def peek(offset = 1)
      @tokens[@position + offset]
    end

    def consume(expected_type = nil)
      return nil if eof?
      return nil if expected_type && current&.type != expected_type

      token = current
      @position += 1
      token
    end

    def eof?
      @position >= @tokens.length
    end

    # Ruby Enumerable support
    def each
      while !eof?
        yield consume
      end
    end

    # StringScanner-inspired methods
    def scan(type)
      consume if check(type)
    end

    def check(type)
      current&.type == type
    end

    def skip(type)
      @position += 1 if check(type)
    end

    # Convenience methods for complex parsing
    def consume_while(&block)
      result = []
      while !eof? && block.call(current)
        result << consume
      end
      result
    end

    def consume_until(&block)
      result = []
      until eof? || block.call(current)
        result << consume
      end
      result
    end

    def skip_whitespace
      consume_while { |token| token.type == :whitespace }
    end

    # Advanced iteration with lookahead
    def each_with_lookahead
      return enum_for(:each_with_lookahead) unless block_given?

      (0...(@tokens.length - 1)).each do |i|
        yield @tokens[i], @tokens[i + 1]
      end
    end

    # StringScanner-inspired position methods
    def rest
      @tokens[@position..]
    end

    def reset
      @position = 0
    end

    def rewind(steps = 1)
      @position = [@position - steps, 0].max
    end

    # Utility methods
    def find_next(type)
      (@position...@tokens.length).find { |i| @tokens[i].type == type }
    end

    def find_next_matching(&block)
      (@position...@tokens.length).find { |i| block.call(@tokens[i]) }
    end

    # Create a new stream starting from current position
    def slice_from_current
      TokenStream.new(@tokens[@position..])
    end

    # Public interface methods to avoid instance_variable_get/set
    attr_reader :tokens

    def position=(new_position)
      @position = [new_position, 0].max
      @position = [@position, @tokens.length].min
    end

    def advance_to(new_position)
      self.position = new_position
    end
  end
end
