# frozen_string_literal: true

require "strscan"

module Cooklang
  Token = Struct.new(:type, :value, :position, :line, :column) do
    def initialize(type, value, position = 0, line = 1, column = 1)
      super
    end
  end

  class Lexer
    TOKENS = {
      ingredient_marker: "@",
      cookware_marker: "#",
      timer_marker: "~",
      open_brace: "{",
      close_brace: "}",
      open_paren: "(",
      close_paren: ")",
      percent: "%",
      comment_line: "--",
      comment_block_start: "[-",
      comment_block_end: "-]",
      metadata_marker: ">>",
      section_marker: "=",
      note_marker: ">",
      newline: "\n",
      yaml_delimiter: "---"
    }.freeze

    def initialize(input)
      @input = input
      @scanner = StringScanner.new(input)
      @line = 1
      @column = 1
      @tokens = []
    end

    def tokenize
      @tokens = []

      until @scanner.eos?
        if match_yaml_delimiter
        elsif match_comment_block
        elsif match_comment_line
        elsif match_metadata_marker
        elsif match_section_marker
        elsif match_note_marker
        elsif match_special_chars
        elsif match_newline
        elsif match_text
        elsif match_hyphen
        else
          # Skip unrecognized character
          advance_position(@scanner.getch)
        end
      end

      @tokens
    end

    private
      def current_position
        @scanner.pos
      end

      def current_line
        @line
      end

      def current_column
        @column
      end

      def advance_position(text)
        text.each_char do |char|
          if char == "\n"
            @line += 1
            @column = 1
          else
            @column += 1
          end
        end
      end

      def add_token(type, value)
        position = current_position
        line = current_line
        column = current_column
        @tokens << Token.new(type, value, position, line, column)
        advance_position(value)
      end

      def capture_single_char_token(type)
        position = current_position
        line = current_line
        column = current_column
        value = @scanner.getch
        @tokens << Token.new(type, value, position, line, column)
        advance_position(value)
        true
      end

      def match_yaml_delimiter
        if @scanner.check(/^---/)
          position = current_position
          line = current_line
          column = current_column
          value = @scanner.scan("---")
          @tokens << Token.new(:yaml_delimiter, value, position, line, column)
          advance_position(value)
          true
        else
          false
        end
      end

      def match_comment_block
        if @scanner.check(/\[-/)
          position = current_position
          line = current_line
          column = current_column
          @scanner.scan("[-")
          @tokens << Token.new(:comment_block_start, "[-", position, line, column)
          advance_position("[-")

          # Scan until block end or EOF
          content = ""
          content += @scanner.getch while !@scanner.eos? && !@scanner.check(/-\]/)

          add_token(:text, content) unless content.empty?

          if @scanner.check(/-\]/)
            position = current_position
            line = current_line
            column = current_column
            @scanner.scan("-]")
            @tokens << Token.new(:comment_block_end, "-]", position, line, column)
            advance_position("-]")
          end

          true
        else
          false
        end
      end

      def match_comment_line
        if @scanner.check(/--/)
          position = current_position
          line = current_line
          column = current_column
          value = @scanner.scan("--")
          @tokens << Token.new(:comment_line, value, position, line, column)
          advance_position(value)

          # Scan rest of line
          line_content = @scanner.scan(/[^\n]*/)
          add_token(:text, line_content) if line_content && !line_content.empty?

          true
        else
          false
        end
      end

      def match_metadata_marker
        if @scanner.check(/>>/)
          position = current_position
          line = current_line
          column = current_column
          value = @scanner.scan(">>")
          @tokens << Token.new(:metadata_marker, value, position, line, column)
          advance_position(value)
          true
        else
          false
        end
      end

      def match_section_marker
        if @scanner.check(/=+/)
          position = current_position
          line = current_line
          column = current_column
          value = @scanner.scan(/=+/)
          @tokens << Token.new(:section_marker, value, position, line, column)
          advance_position(value)
          true
        else
          false
        end
      end

      def match_note_marker
        # Only match > if it's not part of >>
        if @scanner.check(/>/) && !@scanner.check(/>>/)
          position = current_position
          line = current_line
          column = current_column
          value = @scanner.scan(">")
          @tokens << Token.new(:note_marker, value, position, line, column)
          advance_position(value)
          true
        else
          false
        end
      end

      def match_special_chars
        char = @scanner.check(/./)

        case char
        when "@"
          capture_single_char_token(:ingredient_marker)
        when "#"
          capture_single_char_token(:cookware_marker)
        when "~"
          capture_single_char_token(:timer_marker)
        when "{"
          capture_single_char_token(:open_brace)
        when "}"
          capture_single_char_token(:close_brace)
        when "("
          capture_single_char_token(:open_paren)
        when ")"
          capture_single_char_token(:close_paren)
        when "%"
          capture_single_char_token(:percent)
        else
          false
        end
      end

      def match_newline
        if @scanner.check(/\n/)
          position = current_position
          line = current_line
          column = current_column
          value = @scanner.scan("\n")
          @tokens << Token.new(:newline, value, position, line, column)
          advance_position(value)
          true
        else
          false
        end
      end

      def match_text
        # Match any printable text that's not a special character, including spaces and tabs
        # Exclude [ and ] to allow block comment detection
        # Exclude = and > to allow section and note markers
        # Include tabs explicitly along with printable characters
        if @scanner.check(/[\t[:print:]&&[^@#~{}()%\n\-\[\]=>]]+/)
          position = current_position
          line = current_line
          column = current_column
          text = @scanner.scan(/[\t[:print:]&&[^@#~{}()%\n\-\[\]=>]]+/)
          @tokens << Token.new(:text, text, position, line, column)
          advance_position(text)
          true
        else
          false
        end
      end

      def match_hyphen
        if @scanner.check(/-/) && !@scanner.check(/--/)
          position = current_position
          line = current_line
          column = current_column
          @scanner.scan("-")
          @tokens << Token.new(:hyphen, "-", position, line, column)
          advance_position("-")
          true
        else
          false
        end
      end
  end
end
