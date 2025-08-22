# frozen_string_literal: true

module Cooklang
  class Metadata < Hash
    def initialize(data = {})
      super()
      data.each { |key, value| self[key.to_s] = value }
    end

    def []=(key, value)
      super(key.to_s, value)
    end

    def [](key)
      super(key.to_s)
    end

    def key?(key)
      super(key.to_s)
    end

    def delete(key)
      super(key.to_s)
    end

    def fetch(key, *)
      super(key.to_s, *)
    end

    def to_h
      super
    end

    def servings
      self["servings"]&.to_i
    end

    def servings=(value)
      self["servings"] = value
    end

    def prep_time
      self["prep_time"] || self["prep-time"]
    end

    def prep_time=(value)
      self["prep_time"] = value
    end

    def cook_time
      self["cook_time"] || self["cook-time"]
    end

    def cook_time=(value)
      self["cook_time"] = value
    end

    def total_time
      self["total_time"] || self["total-time"]
    end

    def total_time=(value)
      self["total_time"] = value
    end

    def title
      self["title"]
    end

    def title=(value)
      self["title"] = value
    end

    def source
      self["source"]
    end

    def source=(value)
      self["source"] = value
    end

    def tags
      value = self["tags"]
      case value
      when Array
        value
      when String
        value.split(",").map(&:strip)
      else
        []
      end
    end

    def tags=(value)
      self["tags"] = value
    end
  end
end
