# frozen_string_literal: true

module Cooklang
  class Step
    attr_reader :segments

    def initialize(segments:)
      @segments = segments.freeze
    end

    def to_text
      @segments.map do |segment|
        case segment
        when Hash
          case segment[:type]
          when :ingredient
            segment[:name]
          when :cookware
            segment[:name]
          when :timer
            segment[:name] || "timer"
          else
            segment[:value] || ""
          end
        when String
          segment
        when Ingredient
          segment.name
        when Cookware
          segment.name
        when Timer
          if segment.name
            "#{segment.name} for #{segment.duration} #{segment.unit}"
          elsif segment.duration && segment.unit
            "for #{segment.duration} #{segment.unit}"
          else
            "timer"
          end
        else
          segment.to_s
        end
      end.join.rstrip
    end

    def to_h
      {
        segments: @segments
      }
    end

    def ==(other)
      return false unless other.is_a?(Step)

      segments == other.segments
    end

    def eql?(other)
      self == other
    end

    def hash
      segments.hash
    end

    def ingredients_used
      @segments.filter_map { |segment| segment[:name] if segment.is_a?(Hash) && segment[:type] == :ingredient }
    end

    def cookware_used
      @segments.filter_map { |segment| segment[:name] if segment.is_a?(Hash) && segment[:type] == :cookware }
    end

    def timers_used
      @segments.select { |segment| segment.is_a?(Hash) && segment[:type] == :timer }
    end

    def has_ingredients?
      ingredients_used.any?
    end

    def has_cookware?
      cookware_used.any?
    end

    def has_timers?
      timers_used.any?
    end
  end
end
