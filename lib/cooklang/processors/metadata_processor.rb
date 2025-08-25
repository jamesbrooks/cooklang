# frozen_string_literal: true

require_relative "../metadata"

module Cooklang
  module Processors
    class MetadataProcessor
      class << self
        def extract_metadata(tokens)
          metadata = Metadata.new
          content_tokens = []
          0

          # Check for YAML front matter
          if tokens.first&.type == :yaml_delimiter
            metadata, content_tokens, _ = extract_yaml_frontmatter(tokens)
          else
            content_tokens = tokens.dup
          end

          # Extract inline metadata
          extract_inline_metadata(content_tokens, metadata)

          [metadata, content_tokens]
        end

        private
          def extract_yaml_frontmatter(tokens)
            metadata = Metadata.new
            i = 1 # Skip the first ---
            yaml_content = []

            # Find the closing --- delimiter
            while i < tokens.length
              if tokens[i].type == :yaml_delimiter
                # Found closing delimiter
                break
              elsif tokens[i].type == :text
                yaml_content << tokens[i].value
              elsif tokens[i].type == :newline
                yaml_content << "\n"
              elsif tokens[i].type == :metadata_marker
                yaml_content << ">>"
              end
              i += 1
            end

            # Skip the closing --- if we found it
            i += 1 if i < tokens.length && tokens[i].type == :yaml_delimiter

            # Parse YAML content if we have any
            if yaml_content.any?
              yaml_text = yaml_content.join.strip
              parse_yaml_content(yaml_text, metadata) unless yaml_text.empty?
            end

            # Return remaining tokens
            remaining_tokens = tokens[i..]

            [metadata, remaining_tokens, i]
          end

          def parse_yaml_content(yaml_text, metadata)
            # Simple YAML parsing - split by lines and parse key-value pairs
            yaml_text.split("\n").each do |line|
              line = line.strip
              next if line.empty? || line.start_with?("#")

              if line.match(/^([^:]+):\s*(.*)$/)
                key = ::Regexp.last_match(1).strip
                value = ::Regexp.last_match(2).strip

                # Remove quotes if present
                value = value.gsub(/^["']|["']$/, "") if value.match?(/^["'].*["']$/)

                # Parse numeric values
                parsed_value = parse_metadata_value(value)
                metadata[key] = parsed_value unless value.empty?
              end
            end
          end

          def extract_inline_metadata(tokens, metadata)
            tokens_to_remove = []

            tokens.each_with_index do |token, index|
              next unless token.type == :metadata_marker

              # Look for metadata pattern: >> key: value
              if index + 1 < tokens.length && tokens[index + 1].type == :text
                text = tokens[index + 1].value.strip

                if text.match(/^([^:]+):\s*(.+)$/)
                  key = ::Regexp.last_match(1).strip
                  value = ::Regexp.last_match(2).strip

                  # Remove quotes if present
                  value = value.gsub(/^["']|["']$/, "") if value.match?(/^["'].*["']$/)

                  # Parse numeric values
                  parsed_value = parse_metadata_value(value)
                  metadata[key] = parsed_value

                  # Mark both marker and text tokens for removal
                  tokens_to_remove << index << (index + 1)
                end
              end
            end

            # Remove only the specific metadata tokens that were processed
            tokens.reject!.with_index { |token, index| tokens_to_remove.include?(index) }
          end

          def parse_metadata_value(value)
            return value if value.empty?

            # Try to parse as integer
            return value.to_i if value.match?(/^\d+$/)

            # Try to parse as float
            return value.to_f if value.match?(/^\d+\.\d+$/)

            # Return as string
            value
          end
      end
    end
  end
end
