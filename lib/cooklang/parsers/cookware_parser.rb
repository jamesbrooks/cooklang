# frozen_string_literal: true

require_relative "../cookware"
require_relative "../token_stream"

module Cooklang
  module Parsers
    class CookwareParser
      def initialize(stream)
        @stream = stream
      end

      def parse
        return nil unless @stream.current&.type == :cookware_marker
        @stream.consume(:cookware_marker) # Skip the # marker

        return nil if invalid_syntax?

        brace_index = find_next_brace
        has_valid_brace = brace_index && !brace_belongs_to_other_marker?(brace_index)

        if has_valid_brace
          parse_braced_cookware(brace_index)
        else
          parse_simple_cookware
        end
      end

      private
        def invalid_syntax?
          @stream.current&.type == :text && @stream.current.value.start_with?(" ")
        end

        def find_next_brace
          @stream.find_next(:open_brace)
        end

        def brace_belongs_to_other_marker?(brace_index)
          current_pos = @stream.position

          while @stream.position < brace_index && !@stream.eof?
            if %i[ingredient_marker cookware_marker timer_marker].include?(@stream.current.type)
              @stream.advance_to(current_pos)
              return true
            end
            @stream.consume
          end

          @stream.advance_to(current_pos)
          false
        end

        def parse_braced_cookware(brace_index)
          name = extract_name_until_brace(brace_index)
          @stream.consume(:open_brace) # Skip open brace

          quantity = extract_quantity
          @stream.consume(:close_brace) # Skip close brace

          quantity = 1 if quantity.nil? || quantity == ""

          Cookware.new(name: name, quantity: quantity)
        end

        def parse_simple_cookware
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

          cookware_item = Cookware.new(name: name, quantity: 1)
          [cookware_item, remaining_text]
        end

        def extract_name_until_brace(brace_index)
          name_parts = []

          while @stream.position < brace_index && !@stream.eof?
            case @stream.current.type
            when :text, :hyphen
              name_parts << @stream.current.value
            end
            @stream.consume
          end

          name_parts.join.strip
        end

        def extract_quantity
          text_parts = []

          while !@stream.eof? && @stream.current.type != :close_brace
            case @stream.current.type
            when :percent
              # Skip percent in cookware - quantity comes after
              @stream.consume
            when :text
              text_parts << @stream.current.value
              @stream.consume
            else
              @stream.consume
            end
          end

          return nil if text_parts.empty?

          combined_text = text_parts.join.strip
          parse_quantity_value(combined_text)
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
    end
  end
end
