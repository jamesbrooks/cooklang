# frozen_string_literal: true

module Cooklang
  class Ingredient
    attr_reader :name, :quantity, :unit, :notes

    def initialize(name:, quantity: nil, unit: nil, notes: nil)
      @name = name.to_s.freeze
      @quantity = quantity
      @unit = unit&.to_s&.freeze
      @notes = notes&.to_s&.freeze
    end

    def to_s
      result = @name
      result += " #{@quantity}" if @quantity
      result += " #{@unit}" if @unit
      result += " (#{@notes})" if @notes
      result
    end

    def to_h
      {
        name: @name,
        quantity: @quantity,
        unit: @unit,
        notes: @notes
      }.compact
    end

    def ==(other)
      return false unless other.is_a?(Ingredient)

      name == other.name &&
        quantity == other.quantity &&
        unit == other.unit &&
        notes == other.notes
    end

    def eql?(other)
      self == other
    end

    def hash
      [name, quantity, unit, notes].hash
    end

    def has_quantity?
      !@quantity.nil?
    end

    def has_unit?
      !@unit.nil?
    end

    def has_notes?
      !@notes.nil?
    end
  end
end
