# frozen_string_literal: true

module Cooklang
  class Section
    attr_reader :name, :steps

    def initialize(name:, steps: [])
      @name = name&.to_s&.freeze
      @steps = steps.freeze
    end

    def to_s
      name || "Section"
    end

    def to_h
      {
        name: name,
        steps: steps.map(&:to_h)
      }.compact
    end

    def ==(other)
      other.is_a?(Section) &&
        name == other.name &&
        steps == other.steps
    end

    def hash
      [name, steps].hash
    end
  end
end
