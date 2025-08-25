# frozen_string_literal: true

module Cooklang
  class Recipe
    attr_reader :ingredients, :cookware, :timers, :steps, :metadata, :sections, :notes

    def initialize(**components)
      @ingredients = freeze_component(components[:ingredients])
      @cookware = freeze_component(components[:cookware])
      @timers = freeze_component(components[:timers])
      @steps = freeze_component(components[:steps])
      @metadata = components[:metadata] || Metadata.new
      @sections = freeze_component(components[:sections])
      @notes = freeze_component(components[:notes])
    end

    private
      def freeze_component(value)
        (value || []).freeze
      end

    public

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

      comparable_attributes.all? do |attr|
        send(attr) == other.send(attr)
      end
    end

    private
      def comparable_attributes
        %i[ingredients cookware timers steps metadata sections notes]
      end

    public

    def eql?(other)
      self == other
    end

    def hash
      [ingredients, cookware, timers, steps, metadata].hash
    end
  end
end
