# frozen_string_literal: true

module Cooklang
  class Cookware
    attr_reader :name, :quantity

    def initialize(name:, quantity: nil)
      @name = name.to_s.freeze
      @quantity = quantity
    end

    def to_s
      result = @name
      result += " (#{@quantity})" if @quantity
      result
    end

    def to_h
      {
        name: @name,
        quantity: @quantity
      }.compact
    end

    def ==(other)
      return false unless other.is_a?(Cookware)

      name == other.name && quantity == other.quantity
    end

    def eql?(other)
      self == other
    end

    def hash
      [name, quantity].hash
    end

    def has_quantity?
      !@quantity.nil?
    end
  end
end
