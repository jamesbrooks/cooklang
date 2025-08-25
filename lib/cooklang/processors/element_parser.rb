# frozen_string_literal: true

require_relative "../token_stream"
require_relative "../parsers/ingredient_parser"
require_relative "../parsers/cookware_parser"
require_relative "../parsers/timer_parser"

module Cooklang
  module Processors
    class ElementParser
      class << self
        def parse_ingredient(tokens, start_index)
          parse_with_parser(tokens, start_index, Parsers::IngredientParser)
        end

        def parse_cookware(tokens, start_index)
          parse_with_parser(tokens, start_index, Parsers::CookwareParser)
        end

        def parse_timer(tokens, start_index)
          parse_with_parser(tokens, start_index, Parsers::TimerParser)
        end

        private
          def parse_with_parser(tokens, start_index, parser_class)
            stream = TokenStream.new(tokens)
            stream.advance_to(start_index)

            parser = parser_class.new(stream)
            result = parser.parse
            consumed = stream.position - start_index

            # Handle the return format
            if result.is_a?(Array)
              [result[0], consumed, result[1]]
            elsif result
              [result, consumed, nil]
            else
              [nil, 1, nil]
            end
          end
      end
    end
  end
end
