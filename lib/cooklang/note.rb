# frozen_string_literal: true

module Cooklang
  class Note
    attr_reader :content

    def initialize(content:)
      @content = content.to_s.freeze
    end

    def to_s
      content
    end

    def to_h
      { content: content }
    end

    def ==(other)
      other.is_a?(Note) && content == other.content
    end

    def hash
      content.hash
    end
  end
end
