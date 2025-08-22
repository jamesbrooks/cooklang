# frozen_string_literal: true

module Cooklang
  class Timer
    attr_reader :name, :duration, :unit

    def initialize(duration:, unit:, name: nil)
      @name = name&.to_s&.freeze
      @duration = duration
      @unit = unit.to_s.freeze
    end

    def to_s
      result = ""
      result += "#{@name}: " if @name
      result += "#{@duration} #{@unit}"
      result
    end

    def to_h
      {
        name: @name,
        duration: @duration,
        unit: @unit
      }.compact
    end

    def ==(other)
      return false unless other.is_a?(Timer)

      name == other.name &&
        duration == other.duration &&
        unit == other.unit
    end

    def eql?(other)
      self == other
    end

    def hash
      [name, duration, unit].hash
    end

    def total_seconds
      case @unit.downcase
      when "second", "seconds", "sec", "s"
        @duration
      when "minute", "minutes", "min", "m"
        @duration * 60
      when "hour", "hours", "hr", "h"
        @duration * 3600
      when "day", "days", "d"
        @duration * 86_400
      else
        @duration
      end
    end

    def has_name?
      !@name.nil?
    end
  end
end
