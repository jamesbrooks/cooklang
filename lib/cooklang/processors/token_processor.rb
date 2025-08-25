# frozen_string_literal: true

require_relative "../lexer"
require_relative "../note"

module Cooklang
  module Processors
    class TokenProcessor
      class << self
        def strip_comments(tokens)
          result = []
          i = 0

          while i < tokens.length
            token = tokens[i]

            case token.type
            when :comment_line
              i = handle_comment_line(tokens, i, result)
            when :comment_block_start
              i = skip_comment_block(tokens, i)
            else
              result << token
              i += 1
            end
          end

          result
        end

        def extract_notes(tokens)
          notes = []
          content_tokens = []
          i = 0

          while i < tokens.length
            if tokens[i].type == :note_marker
              note_content, i = extract_single_note(tokens, i)
              notes << Note.new(content: note_content) unless note_content.empty?
            else
              content_tokens << tokens[i]
              i += 1
            end
          end

          [notes, content_tokens]
        end

        private
          def extract_single_note(tokens, start_index)
            note_text = ""
            i = start_index + 1 # Skip >

            while i < tokens.length && tokens[i].type != :newline
              note_text += tokens[i].value if tokens[i].type == :text
              i += 1
            end

            [note_text.strip, i]
          end

          def handle_comment_line(tokens, index, result)
            index += 1
            return skip_to_newline(tokens, index) unless index < tokens.length && tokens[index].type == :text

            text_token = tokens[index]
            newline_pos = text_token.value.index("\n")

            if newline_pos
              handle_text_with_newline(text_token, newline_pos, result)
              index + 1
            else
              skip_to_newline(tokens, index + 1)
            end
          end

          def handle_text_with_newline(text_token, newline_pos, result)
            remaining_text = text_token.value[(newline_pos + 1)..]
            return unless remaining_text && !remaining_text.empty?

            result << Token.new(
              :text,
              remaining_text,
              text_token.position,
              text_token.line,
              text_token.column
            )
          end

          def skip_to_newline(tokens, index)
            index += 1 while index < tokens.length && tokens[index].type != :newline
            index
          end

          def skip_comment_block(tokens, index)
            index += 1
            index += 1 while index < tokens.length && tokens[index].type != :comment_block_end
            index += 1 if index < tokens.length && tokens[index].type == :comment_block_end
            index
          end
      end
    end
  end
end
