# frozen_string_literal: true

require_relative "lexer"
require_relative "processors/metadata_processor"
require_relative "processors/token_processor"
require_relative "processors/step_processor"
require_relative "builders/recipe_builder"

module Cooklang
  class Parser
    def parse(input)
      # Tokenize input
      lexer = Lexer.new(input)
      tokens = lexer.tokenize

      # Extract metadata
      metadata, content_tokens = Processors::MetadataProcessor.extract_metadata(tokens)

      # Clean up tokens
      cleaned_tokens = Processors::TokenProcessor.strip_comments(content_tokens)
      notes, recipe_tokens = Processors::TokenProcessor.extract_notes(cleaned_tokens)

      # Parse steps
      parsed_steps = Processors::StepProcessor.parse_steps(recipe_tokens)

      # Build final recipe
      recipe = Builders::RecipeBuilder.build_recipe(parsed_steps, metadata)

      # Add notes to recipe (create new recipe with notes)
      Recipe.new(
        ingredients: recipe.ingredients,
        cookware: recipe.cookware,
        timers: recipe.timers,
        steps: recipe.steps,
        metadata: recipe.metadata,
        sections: recipe.sections,
        notes: notes
      )
    end
  end
end
