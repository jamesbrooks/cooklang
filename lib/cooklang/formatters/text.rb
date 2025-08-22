# frozen_string_literal: true

require_relative "../formatter"

module Cooklang
  module Formatters
    class Text < Formatter
      def to_s
        sections = []

        sections << ingredients_section unless recipe.ingredients.empty?
        sections << steps_section unless recipe.steps.empty?

        sections.join("\n").strip
      end
    end
  end
end
