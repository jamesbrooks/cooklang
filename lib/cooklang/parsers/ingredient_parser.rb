# frozen_string_literal: true

require_relative "../ingredient"
require_relative "../token_stream"

module Cooklang
  module Parsers
    class IngredientParser
      def initialize(stream)
        @stream = stream
      end

      def parse
        return nil unless @stream.current&.type == :ingredient_marker
        @stream.consume(:ingredient_marker) # Skip the @ marker

        return nil if invalid_syntax?

        brace_index = find_next_brace

        if brace_index
          parse_braced_ingredient(brace_index)
        else
          parse_simple_ingredient
        end
      end

      private
        def invalid_syntax?
          @stream.current&.type == :text && @stream.current.value.start_with?(" ")
        end

        def find_next_brace
          @stream.find_next(:open_brace)
        end

        def parse_braced_ingredient(brace_index)
          name = extract_name_until_brace(brace_index)
          @stream.consume(:open_brace) # Skip open brace

          quantity, unit = extract_quantity_and_unit
          @stream.consume(:close_brace) # Skip close brace

          notes = extract_notes

          # Default values according to original logic
          quantity = "some" if (quantity.nil? || quantity == "") && (unit.nil? || unit == "")
          unit = nil if unit == ""

          Ingredient.new(name: name, quantity: quantity, unit: unit, notes: notes)
        end

        def parse_simple_ingredient
          remaining_text = nil

          if @stream.current&.type == :text
            text = @stream.current.value
            if text.match(/^([a-zA-Z0-9_]+)(.*)$/)
              name = ::Regexp.last_match(1)
              remaining_text = ::Regexp.last_match(2)
            else
              name = text.strip
            end
            @stream.consume
          else
            name = ""
          end

          ingredient = Ingredient.new(name: name, quantity: "some", unit: nil, notes: nil)
          [ingredient, remaining_text]
        end

        def extract_name_until_brace(brace_index)
          name_parts = []
          @stream.position

          while @stream.position < brace_index && !@stream.eof?
            case @stream.current.type
            when :text, :hyphen
              name_parts << @stream.current.value
            end
            @stream.consume
          end

          name_parts.join.strip
        end

        def extract_quantity_and_unit
          quantity = nil
          unit = nil
          text_parts = []

          while !@stream.eof? && @stream.current.type != :close_brace
            case @stream.current.type
            when :percent
              if !text_parts.empty?
                quantity_text = text_parts.join.strip
                quantity = parse_quantity_value(quantity_text)
              end
              text_parts = []
              @stream.consume
            when :text
              text_parts << @stream.current.value
              @stream.consume
            else
              @stream.consume
            end
          end

          if !text_parts.empty?
            combined_text = text_parts.join.strip
            if quantity.nil?
              # Try to parse as numeric quantity first, fallback to string if not purely numeric
              if combined_text.match?(/^\d+$/)
                quantity = combined_text.to_i
                unit = ""
              elsif combined_text.match?(/^\d+\.\d+$/)
                quantity = combined_text.to_f
                unit = ""
              else
                # Non-numeric content, keep as string quantity
                quantity = combined_text
                unit = ""
              end
            else
              unit = combined_text
            end
          end

          [quantity, unit]
        end

        def parse_quantity_value(text)
          case text
          when /^\d+$/
            text.to_i
          when /^\d+\.\d+$/
            text.to_f
          else
            text
          end
        end

        def extract_quantity_from_text(text)
          # Simple quantity extraction - this could use QuantityExtractor if needed
          if text.match(/^(\d+(?:\.\d+)?)\s*(.*)$/)
            quantity_val = ::Regexp.last_match(1)
            rest = ::Regexp.last_match(2)

            quantity = quantity_val.include?(".") ? quantity_val.to_f : quantity_val.to_i
            unit = rest.empty? ? nil : rest

            [quantity, unit]
          else
            [text, nil]
          end
        end

        def extract_notes
          return nil unless @stream.current&.type == :open_paren

          @stream.consume(:open_paren) # Skip open paren
          notes_parts = []

          while !@stream.eof? && @stream.current.type != :close_paren
            if @stream.current.type == :text
              notes_parts << @stream.current.value
            end
            @stream.consume
          end

          @stream.consume(:close_paren) if @stream.current&.type == :close_paren

          notes = notes_parts.join.strip
          notes.empty? ? nil : notes
        end
    end
  end
end
