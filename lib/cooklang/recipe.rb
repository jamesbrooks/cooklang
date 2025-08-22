# frozen_string_literal: true

module Cooklang
  class Recipe
    attr_reader :ingredients, :cookware, :timers, :steps, :metadata, :sections, :notes

    def initialize(ingredients:, cookware:, timers:, steps:, metadata:, sections: [], notes: [])
      @ingredients = ingredients.freeze
      @cookware = cookware.freeze
      @timers = timers.freeze
      @steps = steps.freeze
      @metadata = metadata
      @sections = sections.freeze
      @notes = notes.freeze
    end

    def ingredients_hash
      @ingredients.each_with_object({}) do |ingredient, hash|
        hash[ingredient.name] = {
          quantity: ingredient.quantity,
          unit: ingredient.unit
        }.compact
      end
    end

    def steps_text
      @steps.map(&:to_text)
    end

    def to_h
      {
        ingredients: @ingredients.map(&:to_h),
        cookware: @cookware.map(&:to_h),
        timers: @timers.map(&:to_h),
        steps: @steps.map(&:to_h),
        metadata: @metadata.to_h,
        sections: @sections.map(&:to_h),
        notes: @notes.map(&:to_h)
      }
    end

    def ==(other)
      return false unless other.is_a?(Recipe)

      ingredients == other.ingredients &&
        cookware == other.cookware &&
        timers == other.timers &&
        steps == other.steps &&
        metadata == other.metadata &&
        sections == other.sections &&
        notes == other.notes
    end

    def eql?(other)
      self == other
    end

    def hash
      [ingredients, cookware, timers, steps, metadata].hash
    end
  end
end
