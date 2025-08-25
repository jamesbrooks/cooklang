# frozen_string_literal: true

require_relative "../timer"
require_relative "../token_stream"

module Cooklang
  module Parsers
    class TimerParser
      def initialize(stream)
        @stream = stream
      end

      def parse
        return nil unless @stream.current&.type == :timer_marker
        @stream.consume(:timer_marker) # Skip the ~ marker

        return nil if invalid_syntax?

        brace_index = find_next_brace

        if brace_index
          parse_named_timer(brace_index)
        else
          parse_simple_timer
        end
      end

      private
        def invalid_syntax?
          @stream.current&.type == :text && @stream.current.value.start_with?(" ")
        end

        def find_next_brace
          @stream.find_next(:open_brace)
        end

        def parse_named_timer(brace_index)
          name = nil

          # Extract name if there's text before the brace
          if @stream.position < brace_index && @stream.current&.type == :text
            name = @stream.current.value.strip
            @stream.advance_to(brace_index)
          end

          @stream.consume(:open_brace) # Skip open brace

          duration, unit = extract_duration
          @stream.consume(:close_brace) # Skip close brace

          Timer.new(name: name, duration: duration, unit: unit)
        end

        def parse_simple_timer
          remaining_text = nil
          name = nil

          if @stream.current&.type == :text
            text = @stream.current.value
            if text.match(/^([a-zA-Z0-9_]+)(.*)$/)
              name = ::Regexp.last_match(1)
              remaining_text = ::Regexp.last_match(2)
            else
              name = text.strip
            end
            @stream.consume
          end

          timer = Timer.new(name: name, duration: nil, unit: nil)
          [timer, remaining_text]
        end

        def extract_duration
          duration_parts = []
          unit = nil

          while !@stream.eof? && @stream.current.type != :close_brace
            case @stream.current.type
            when :text, :hyphen
              duration_parts << @stream.current.value
              @stream.consume
            when :percent
              @stream.consume
              # Unit comes after percent
              if @stream.current&.type == :text
                unit = @stream.current.value
                @stream.consume
              end
            else
              @stream.consume
            end
          end

          return [nil, nil] if duration_parts.empty?

          duration_text = duration_parts.join

          if unit
            duration = parse_duration_value(duration_text)
            [duration, unit]
          else
            parse_duration_with_unit(duration_text)
          end
        end

        def parse_duration_value(text)
          case text
          when /^\d+$/
            text.to_i
          when /^\d+\.\d+$/
            text.to_f
          else
            text # Keep ranges like "2-3"
          end
        end

        def parse_duration_with_unit(text)
          # Simple duration parsing - could be enhanced with DurationExtractor
          # First check if it's just a number (integer or decimal)
          if text.match?(/^(\d+(?:\.\d+)?)$/)
            parsed_duration = text.include?(".") ? text.to_f : text.to_i
            [parsed_duration, nil]
          elsif text.match(/^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$/)
            duration = ::Regexp.last_match(1)
            unit = ::Regexp.last_match(2)

            parsed_duration = duration.include?(".") ? duration.to_f : duration.to_i
            [parsed_duration, unit]
          else
            [text, nil]
          end
        end
    end
  end
end
