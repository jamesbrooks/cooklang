# frozen_string_literal: true

require_relative "cooklang/version"
require_relative "cooklang/lexer"
require_relative "cooklang/parser"
require_relative "cooklang/recipe"
require_relative "cooklang/ingredient"
require_relative "cooklang/cookware"
require_relative "cooklang/timer"
require_relative "cooklang/step"
require_relative "cooklang/metadata"
require_relative "cooklang/section"
require_relative "cooklang/note"
require_relative "cooklang/formatter"
require_relative "cooklang/formatters/text"

module Cooklang
  class Error < StandardError; end
  class ParseError < Error; end

  def self.parse(input)
    parser = Parser.new
    parser.parse(input)
  end

  def self.parse_file(file_path)
    parse(File.read(file_path))
  end
end
