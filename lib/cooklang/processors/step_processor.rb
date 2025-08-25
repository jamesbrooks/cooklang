# frozen_string_literal: true

require_relative "element_parser"
require_relative "../token_stream"
require_relative "../builders/step_builder"

module Cooklang
  module Processors
    class StepProcessor
      class << self
        def parse_steps(tokens)
          # Group tokens into steps (separated by blank lines)
          step_groups = split_into_step_groups(tokens)

          # Parse each step group into step data
          steps = step_groups.map { |step_tokens| parse_step(step_tokens) }

          # Filter out nil steps (those without content)
          steps.compact.select { |step_data| step_data.is_a?(Hash) && has_content?(step_data[:segments]) }
        end

        private
          def split_into_step_groups(tokens)
            groups = []
            current_group = []
            i = 0

            while i < tokens.length
              token = tokens[i]

              if token.type == :newline && blank_line_ahead?(tokens, i)
                groups = finalize_current_group(groups, current_group)
                current_group = []
                i = skip_blank_line(tokens, i)
              else
                current_group << token
                i += 1
              end
            end

            finalize_current_group(groups, current_group)
          end

          def blank_line_ahead?(tokens, index)
            next_index = index + 1
            return false if next_index >= tokens.length

            # Look for consecutive newlines or newline + whitespace + newline
            if tokens[next_index].type == :newline
              true
            elsif tokens[next_index].type == :text && tokens[next_index].value.strip.empty?
              # Check if there's a newline after the whitespace
              next_next_index = next_index + 1
              next_next_index < tokens.length && tokens[next_next_index].type == :newline
            else
              false
            end
          end

          def parse_step(tokens)
            builder = Builders::StepBuilder.new
            stream = TokenStream.new(tokens)

            while !stream.eof?
              process_token_with_stream(stream, builder)
            end

            return nil unless builder.has_content?

            # Return the expected hash format for compatibility
            {
              segments: builder.send(:remove_trailing_newlines, builder.segments.dup),
              ingredients: builder.ingredients,
              cookware: builder.cookware,
              timers: builder.timers,
              section_name: builder.section_name
            }
          end

          def process_token_with_stream(stream, builder)
            token = stream.current

            case token.type
            when :ingredient_marker
              process_ingredient_with_stream(stream, builder)
            when :cookware_marker
              process_cookware_with_stream(stream, builder)
            when :timer_marker
              process_timer_with_stream(stream, builder)
            when :text
              builder.add_text(token.value)
              stream.consume
            when :newline
              builder.add_text("\n")
              stream.consume
            when :yaml_delimiter
              # Preserve yaml_delimiter as literal text when not in YAML context
              builder.add_text(token.value)
              stream.consume
            when :open_brace, :close_brace, :open_paren, :close_paren, :percent
              builder.add_text(token.value)
              stream.consume
            when :section_marker
              process_section_with_stream(stream, builder)
            else
              stream.consume
            end
          end


          def process_ingredient_with_stream(stream, builder)
            process_element_with_stream(stream, builder, :ingredient)
          end

          def process_cookware_with_stream(stream, builder)
            process_element_with_stream(stream, builder, :cookware)
          end

          def process_timer_with_stream(stream, builder)
            process_element_with_stream(stream, builder, :timer)
          end

          def process_element_with_stream(stream, builder, element_type)
            # Get the current position to pass to ElementParser
            start_index = stream.position
            tokens = stream.tokens

            # Parse the element using the appropriate ElementParser method
            element, consumed, remaining_text = case element_type
            when :ingredient
              ElementParser.parse_ingredient(tokens, start_index)
            when :cookware
              ElementParser.parse_cookware(tokens, start_index)
            when :timer
              ElementParser.parse_timer(tokens, start_index)
            end

            if element.nil?
              builder.add_text(stream.current.value)
              stream.consume
            else
              # Add the element using the appropriate builder method
              case element_type
              when :ingredient
                builder.add_ingredient(element)
              when :cookware
                builder.add_cookware(element)
              when :timer
                builder.add_timer(element)
              end

              builder.add_remaining_text(remaining_text)
              # Move stream position forward by consumed tokens
              stream.advance_to(start_index + consumed)
            end
          end

          def process_section_with_stream(stream, builder)
            stream.consume # Skip section marker

            if stream.current&.type == :text
              text_content = stream.current.value
              # Handle both actual newlines and literal \n sequences
              newline_pos = text_content.index("\n") || text_content.index("\\n")

              if newline_pos
                # Section name is everything before the newline
                section_name = text_content[0...newline_pos].strip
                builder.set_section_name(section_name)
              else
                # No newline in this token, take the whole text as section name
                section_name = text_content.strip
                builder.set_section_name(section_name)
              end
              stream.consume
            end
          end






          def has_content?(segments)
            segments.any? { |segment| segment != "\n" && !(segment.is_a?(String) && segment.strip.empty?) }
          end

          def finalize_current_group(groups, current_group)
            return groups unless group_has_content?(current_group)

            groups << current_group
            groups
          end

          def group_has_content?(group)
            group.any? { |t| t.type != :newline }
          end

          def skip_blank_line(tokens, start_index)
            i = start_index + 1
            i += 1 while i < tokens.length && (tokens[i].type == :newline ||
                                             (tokens[i].type == :text && tokens[i].value.strip.empty?))
            i
          end
      end
    end
  end
end
