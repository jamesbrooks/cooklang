# frozen_string_literal: true

module Cooklang
  class Formatter
    attr_reader :recipe

    def initialize(recipe)
      @recipe = recipe
    end

    def to_s
      raise NotImplementedError, "Subclasses must implement #to_s"
    end

    private
      def ingredients_section
        return "" if recipe.ingredients.empty?

        ingredient_lines = recipe.ingredients.map do |ingredient|
          format_ingredient(ingredient)
        end

        "Ingredients:\n#{ingredient_lines.join("\n")}\n"
      end

      def steps_section
        return "" if recipe.steps.empty?

        step_lines = recipe.steps.each_with_index.map do |step, index|
          "    #{index + 1}. #{step.to_text}"
        end

        "Steps:\n#{step_lines.join("\n")}\n"
      end

      def format_ingredient(ingredient)
        name = ingredient.name
        quantity_unit = format_quantity_unit(ingredient)

        # Add 4 spaces after the longest ingredient name for alignment
        name_width = max_ingredient_name_length + 4
        "    #{name.ljust(name_width)}#{quantity_unit}"
      end

      def format_quantity_unit(ingredient)
        if ingredient.quantity && ingredient.unit
          "#{ingredient.quantity} #{ingredient.unit}"
        elsif ingredient.quantity
          ingredient.quantity.to_s
        elsif ingredient.unit
          ingredient.unit
        else
          "some"
        end
      end

      def max_ingredient_name_length
        @max_ingredient_name_length ||= recipe.ingredients.map(&:name).map(&:length).max || 0
      end
  end
end
