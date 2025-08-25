# frozen_string_literal: true

require_relative "../step"

module Cooklang
  module Builders
    class StepBuilder
      def initialize
        @segments = []
        @ingredients = []
        @cookware = []
        @timers = []
        @section_name = nil
      end

      def add_text(text)
        @segments << text
        self
      end

      def add_ingredient(ingredient)
        @ingredients << ingredient
        @segments << ingredient
        self
      end

      def add_cookware(cookware)
        @cookware << cookware
        @segments << cookware
        self
      end

      def add_timer(timer)
        @timers << timer
        @segments << timer
        self
      end

      def add_remaining_text(text)
        if text && !text.empty?
          @segments << text
        end
        self
      end

      def set_section_name(name)
        @section_name = name unless name&.empty?
        self
      end

      def build
        # Clean up segments - remove trailing newlines
        cleaned_segments = remove_trailing_newlines(@segments.dup)

        Step.new(segments: cleaned_segments)
      end

      # Check if the step has meaningful content
      def has_content?
        @segments.any? { |segment| segment != "\n" && !(segment.is_a?(String) && segment.strip.empty?) }
      end

      # Access internal collections for compatibility
      attr_reader :segments, :ingredients, :cookware, :timers, :section_name

      private
        def remove_trailing_newlines(segments)
          # Remove trailing newlines and whitespace-only text segments
          segments.pop while !segments.empty? &&
                            (segments.last == "\n" ||
                             (segments.last.is_a?(String) && segments.last.strip.empty?))
          segments
        end
    end
  end
end
