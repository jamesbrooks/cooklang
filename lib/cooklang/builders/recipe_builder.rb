# frozen_string_literal: true

require_relative "../recipe"
require_relative "../step"
require_relative "../section"

module Cooklang
  module Builders
    class RecipeBuilder
      class << self
        def build_recipe(parsed_steps, metadata)
          # Aggregate all elements from steps
          all_ingredients = []
          all_cookware = []
          all_timers = []
          steps = []
          sections = []

          parsed_steps.each do |step_data|
            all_ingredients.concat(step_data[:ingredients])
            all_cookware.concat(step_data[:cookware])
            all_timers.concat(step_data[:timers])

            step = Step.new(segments: step_data[:segments])
            steps << step

            # Create section if this step has a section name
            if step_data[:section_name]
              sections << Section.new(name: step_data[:section_name], steps: [step])
            end
          end

          # Deduplicate ingredients and cookware
          unique_ingredients = deduplicate_ingredients(all_ingredients)
          unique_cookware = deduplicate_cookware(all_cookware)

          Recipe.new(
            ingredients: unique_ingredients,
            cookware: unique_cookware,
            timers: all_timers,
            steps: steps,
            metadata: metadata,
            sections: sections
          )
        end

        private
          def deduplicate_ingredients(ingredients)
            # Group by name AND quantity to preserve different quantities of same ingredient
            grouped = ingredients.group_by { |i| [i.name, i.quantity, i.unit] }
            grouped.values.map(&:first)
          end

          def deduplicate_cookware(cookware_items)
            # Group by name and prefer items with quantity over those without
            cookware_items.group_by(&:name).map do |_name, items|
              # Prefer items with quantity, then take the first one
              items.find(&:quantity) || items.first
            end
          end
      end
    end
  end
end
