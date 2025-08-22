# frozen_string_literal: true

module Cooklang
  class Parser
    def parse(input)
      lexer = Lexer.new(input)
      tokens = lexer.tokenize

      # Extract metadata first
      metadata, content_tokens = extract_metadata(tokens)

      # Extract notes
      notes, content_tokens = extract_notes(content_tokens)

      # Remove comments
      content_tokens = strip_comments(content_tokens)

      # Extract sections and split into steps
      sections, step_token_groups = extract_sections_and_steps(content_tokens)

      # Parse each step
      steps = step_token_groups.map { |step_tokens| parse_step(step_tokens) }

      # Extract ingredients, cookware, timers from all steps
      ingredients = []
      cookware = []
      timers = []

      steps.each do |step|
        ingredients.concat(step[:ingredients])
        cookware.concat(step[:cookware])
        timers.concat(step[:timers])
      end

      # Convert steps to Step objects, filtering out whitespace-only steps
      step_objects = steps.map { |step| Step.new(segments: step[:segments]) }
                          .reject { |step| step.to_text.strip.empty? }

      Recipe.new(
        ingredients: ingredients.uniq { |i| [i.name, i.quantity, i.unit] },
        cookware: deduplicate_cookware(cookware),
        timers: timers,
        steps: step_objects,
        sections: sections,
        notes: notes,
        metadata: Metadata.new(metadata)
      )
    end

    private
      def extract_metadata(tokens)
        metadata = {}
        content_start = 0

        # Check for YAML front matter
        if tokens.first&.type == :yaml_delimiter
          yaml_end = find_yaml_end(tokens)
          if yaml_end
            yaml_content = extract_yaml_content(tokens[1...yaml_end])
            metadata.merge!(yaml_content)
            content_start = yaml_end + 1
          end
        end

        # Extract >> style metadata from remaining tokens
        remaining_tokens = tokens[content_start..]
        metadata_tokens, content_tokens = extract_inline_metadata(remaining_tokens)

        metadata_tokens.each do |token|
          next unless token.type == :metadata_marker

          # Next token should be the key: value text
          next_token = metadata_tokens[metadata_tokens.index(token) + 1]
          parse_metadata_line(next_token.value, metadata) if next_token&.type == :text
        end

        [metadata, content_tokens]
      end

      def find_yaml_end(tokens)
        tokens[1..].find_index { |token| token.type == :yaml_delimiter }&.+(1)
      end

      def extract_yaml_content(yaml_tokens)
        yaml_text = yaml_tokens.filter_map { |t| t.value if %i[text newline].include?(t.type) }
                               .join

        # Simple YAML parsing for key: value pairs
        metadata = {}
        yaml_text.split("\n").each do |line|
          line = line.strip
          next if line.empty?

          next unless line.match(/^([^:]+):\s*(.*)$/)

          key = ::Regexp.last_match(1).strip
          value = ::Regexp.last_match(2).strip
          metadata[key] = parse_metadata_value(value)
        end

        metadata
      end

      def extract_inline_metadata(tokens)
        metadata_tokens = []
        content_tokens = []
        i = 0

        while i < tokens.length
          token = tokens[i]

          if token.type == :metadata_marker
            # Collect metadata line
            metadata_tokens << token
            i += 1

            # Collect the rest of the line
            while i < tokens.length && tokens[i].type != :newline
              metadata_tokens << tokens[i]
              i += 1
            end

            # Include the newline
            if i < tokens.length && tokens[i].type == :newline
              metadata_tokens << tokens[i]
              i + 1
            end
          else
            content_tokens << token
            i += 1
          end
        end

        [metadata_tokens, content_tokens]
      end

      def parse_metadata_line(text, metadata)
        return unless text.match(/^\s*(\w+):\s*(.*)$/)

        key = ::Regexp.last_match(1).strip
        value = ::Regexp.last_match(2).strip
        metadata[key] = parse_metadata_value(value)
      end

      def parse_metadata_value(value)
        # Try to parse as number
        if value.match?(/^\d+$/)
          value.to_i
        elsif value.match?(/^\d+\.\d+$/)
          value.to_f
        else
          value
        end
      end

      def strip_comments(tokens)
        result = []
        i = 0

        while i < tokens.length
          token = tokens[i]

          case token.type
          when :comment_line
            # Skip until newline or process text with embedded newline
            i += 1
            if i < tokens.length && tokens[i].type == :text
              # Check if this text contains a newline
              text = tokens[i].value
              newline_index = text.index("\n")
              if newline_index
                # Split the text at the newline, keep the part after newline
                remaining_text = text[(newline_index + 1)..]
                if remaining_text && !remaining_text.empty?
                  # Create a new token with the remaining text and add it to result
                  result << Token.new(
                    :text,
                    remaining_text,
                    tokens[i].position,
                    tokens[i].line,
                    tokens[i].column
                  )
                else
                  # No remaining text, skip this token
                end
                i += 1
              else
                # No newline in this text, skip it entirely (it's all comment)
                i += 1
                # Continue skipping until we find a newline token
                i += 1 while i < tokens.length && tokens[i].type != :newline
                # Preserve the newline - don't skip it, it will be processed normally
              end
            else
              # Look for separate newline token
              i += 1 while i < tokens.length && tokens[i].type != :newline
              # Preserve the newline - don't skip it, it will be processed normally
            end
          when :comment_block_start
            # Skip until comment_block_end
            i += 1
            i += 1 while i < tokens.length && tokens[i].type != :comment_block_end
            # Skip the comment_block_end token
            i += 1 if i < tokens.length && tokens[i].type == :comment_block_end
          else
            result << token
            i += 1
          end
        end

        result
      end

      def split_into_steps(tokens)
        steps = []
        current_step = []
        consecutive_newlines = 0

        tokens.each do |token|
          if token.type == :newline
            consecutive_newlines += 1
            current_step << token

            # Two consecutive newlines = step boundary
            if consecutive_newlines >= 2 && !current_step.empty?
              steps << current_step.dup
              current_step.clear
              consecutive_newlines = 0
            end
          else
            consecutive_newlines = 0
            current_step << token
          end
        end

        # Add the last step if it has content
        steps << current_step unless current_step.empty?

        # Filter out steps that are only newlines
        steps.select { |step| step.any? { |token| token.type != :newline } }
      end

      def parse_step(tokens)
        segments = []
        ingredients = []
        cookware = []
        timers = []
        i = 0

        while i < tokens.length
          token = tokens[i]

          case token.type
          when :ingredient_marker
            ingredient, consumed, remaining_text = parse_ingredient_at(tokens, i)
            if ingredient.nil?
              # Invalid ingredient syntax, treat @ as plain text
              segments << token.value
              i += 1
            else
              ingredients << ingredient
              segments << ingredient
              # Add any remaining text from partial token consumption
              segments << remaining_text if remaining_text && !remaining_text.empty?
              i += consumed
            end
          when :cookware_marker
            cookware_item, consumed, remaining_text = parse_cookware_at(tokens, i)
            if cookware_item.nil?
              # Invalid cookware syntax, treat # as plain text
              segments << token.value
              i += 1
            else
              cookware << cookware_item
              segments << cookware_item
              # Add any remaining text from partial token consumption
              segments << remaining_text if remaining_text && !remaining_text.empty?
              i += consumed
            end
          when :timer_marker
            timer, consumed, remaining_text = parse_timer_at(tokens, i)
            if timer.nil?
              # Invalid timer syntax, treat ~ as plain text
              segments << token.value
              i += 1
            else
              timers << timer
              segments << timer
              # Add any remaining text from partial token consumption
              segments << remaining_text if remaining_text && !remaining_text.empty?
              i += consumed
            end
          when :text
            segments << token.value
            i += 1
          when :newline
            segments << "\n"
            i += 1
          when :yaml_delimiter
            # YAML delimiters outside of frontmatter should be treated as text
            segments << token.value
            i += 1
          when :open_brace, :close_brace, :open_paren, :close_paren, :percent
            # Standalone punctuation tokens should be treated as text
            segments << token.value
            i += 1
          else
            i += 1
          end
        end

        # Clean up segments - remove trailing newlines
        segments = remove_trailing_newlines(segments)

        {
          segments: segments,
          ingredients: ingredients,
          cookware: cookware,
          timers: timers
        }
      end

      def parse_ingredient_at(tokens, start_index)
        i = start_index + 1 # Skip the @ marker
        name = ""
        quantity = nil
        unit = nil
        notes = nil
        remaining_text = nil

        # Check for invalid syntax first
        if i < tokens.length && tokens[i].type == :text && tokens[i].value.start_with?(" ")
          # Return nil to indicate invalid ingredient (e.g., "@ example")
          return [nil, 1, nil]
        end

        # Look ahead to see if there's a brace - if so, collect everything until the brace
        brace_index = find_next_brace(tokens, i)

        if brace_index
          # Collect all tokens until the brace as the name
          name_parts = []
          while i < brace_index
            case tokens[i].type
            when :text
              name_parts << tokens[i].value
            when :hyphen
              name_parts << tokens[i].value
            end
            i += 1
          end
          name = name_parts.join.strip
        elsif i < tokens.length && tokens[i].type == :text
          # No brace - take only the first word as the ingredient name, stopping at punctuation
          text = tokens[i].value
          if text.match(/^([a-zA-Z0-9_]+)(.*)$/)
            name = ::Regexp.last_match(1)
            remaining_text = ::Regexp.last_match(2)
          else
            # No match, use entire text as name
            name = text.strip
          end
          i += 1
        end

        # Parse quantity/unit if present
        if i < tokens.length && tokens[i].type == :open_brace
          i += 1 # Skip {
          quantity_text = ""

          while i < tokens.length && tokens[i].type != :close_brace
            if tokens[i].type == :percent
              # Split quantity and unit
              if tokens[i + 1]&.type == :text
                unit = tokens[i + 1].value.strip
                i += 2
              else
                i += 1
              end
            elsif tokens[i].type == :text
              quantity_text += tokens[i].value
              i += 1
            else
              i += 1
            end
          end

          i += 1 if i < tokens.length && tokens[i].type == :close_brace # Skip }

          # Parse quantity
          quantity_text = quantity_text.strip
          if quantity_text.match?(/^\d+$/)
            quantity = quantity_text.to_i
          elsif quantity_text.match?(/^\d+\.\d+$/)
            quantity = quantity_text.to_f
          elsif !quantity_text.empty?
            quantity = quantity_text
          end
        end

        # Parse notes if present
        if i < tokens.length && tokens[i].type == :open_paren
          i += 1 # Skip (
          notes_text = ""

          while i < tokens.length && tokens[i].type != :close_paren
            notes_text += tokens[i].value if tokens[i].type == :text
            i += 1
          end

          i += 1 if i < tokens.length && tokens[i].type == :close_paren # Skip )
          notes = notes_text.strip unless notes_text.strip.empty?
        end

        # Set default quantity to "some" if not specified
        quantity = "some" if quantity.nil? && unit.nil?

        ingredient = Ingredient.new(
          name: name,
          quantity: quantity,
          unit: unit,
          notes: notes
        )

        [ingredient, i - start_index, remaining_text]
      end

      def parse_cookware_at(tokens, start_index)
        i = start_index + 1 # Skip the # marker
        name = ""
        quantity = nil
        remaining_text = nil

        # Check for invalid syntax first
        if i < tokens.length && tokens[i].type == :text && tokens[i].value.start_with?(" ")
          # Return nil to indicate invalid cookware (e.g., "# example")
          return [nil, 1, nil]
        end

        # Look ahead to see if there's a brace - if so, collect everything until the brace
        brace_index = find_next_brace(tokens, i)

        if brace_index
          # Collect all tokens until the brace as the name, but stop at other markers
          name_parts = []
          found_other_marker = false
          while i < brace_index
            case tokens[i].type
            when :text
              name_parts << tokens[i].value
            when :hyphen
              name_parts << tokens[i].value
            when :ingredient_marker, :cookware_marker, :timer_marker
              # Stop at other markers - this brace belongs to them
              found_other_marker = true
              break
            end
            i += 1
          end

          if found_other_marker
            # Brace belongs to another element, parse as single-word cookware
            brace_index = nil
            i = start_index + 1 # Reset position
          else
            name = name_parts.join.strip
          end
        end

        if !brace_index && i < tokens.length && tokens[i].type == :text
          # No brace - take only the first word as the cookware name, stopping at punctuation
          text = tokens[i].value
          if text.match(/^([a-zA-Z0-9_]+)(.*)$/)
            name = ::Regexp.last_match(1)
            remaining_text = ::Regexp.last_match(2)
          else
            # No match, use entire text as name
            name = text.strip
          end
          i += 1
        end

        # Parse quantity if present
        if i < tokens.length && tokens[i].type == :open_brace
          i += 1 # Skip {
          quantity_text = ""

          while i < tokens.length && tokens[i].type != :close_brace
            quantity_text += tokens[i].value if tokens[i].type == :text
            i += 1
          end

          i += 1 if i < tokens.length && tokens[i].type == :close_brace # Skip }

          # Parse quantity
          quantity_text = quantity_text.strip
          if quantity_text.match?(/^\d+$/)
            quantity = quantity_text.to_i
          elsif !quantity_text.empty?
            quantity = quantity_text
          end
        end

        # Set default quantity to 1 if not specified
        quantity = 1 if quantity.nil?

        cookware_item = Cookware.new(name: name, quantity: quantity)
        [cookware_item, i - start_index, remaining_text]
      end

      def parse_timer_at(tokens, start_index)
        i = start_index + 1 # Skip the ~ marker
        name = nil
        duration = nil
        unit = nil
        remaining_text = nil

        # Check for invalid syntax first
        if i < tokens.length && tokens[i].type == :text && tokens[i].value.start_with?(" ")
          # Return nil to indicate invalid timer (e.g., "~ example")
          return [nil, 1, nil]
        end

        # Check if we have a name before { or standalone name
        if i < tokens.length && tokens[i].type == :text && !tokens[i].value.strip.empty?
          next_brace_index = find_next_brace(tokens, i)
          if next_brace_index
            # We have a name before braces
            name = tokens[i].value.strip
            i = next_brace_index
          else
            # Standalone timer name (e.g., ~rest) - take only the first word
            text = tokens[i].value
            if text.match(/^([a-zA-Z0-9_]+)(.*)$/)
              name = ::Regexp.last_match(1)
              remaining_text = ::Regexp.last_match(2)
            else
              # No match, use entire text as name
              name = text.strip
            end
            i += 1
          end
        end

        # Parse duration/unit
        if i < tokens.length && tokens[i].type == :open_brace
          i += 1 # Skip {
          duration_text = ""

          while i < tokens.length && tokens[i].type != :close_brace
            case tokens[i].type
            when :percent
              # Split duration and unit
              if tokens[i + 1]&.type == :text
                unit = tokens[i + 1].value.strip
                i += 2
              else
                i += 1
              end
            when :text
              duration_text += tokens[i].value
              i += 1
            when :hyphen
              duration_text += tokens[i].value
              i += 1
            else
              # Skip other token types
              i += 1
            end
          end

          i += 1 if i < tokens.length && tokens[i].type == :close_brace # Skip }

          # Parse duration
          duration_text = duration_text.strip
          if duration_text.match?(/^\d+$/)
            duration = duration_text.to_i
          elsif duration_text.match?(/^\d+\.\d+$/)
            duration = duration_text.to_f
          elsif !duration_text.empty?
            duration = duration_text # Keep as string for ranges like "2-3"
          end
        end

        timer = Timer.new(name: name, duration: duration, unit: unit)
        [timer, i - start_index, remaining_text]
      end

      def find_next_brace(tokens, start_index)
        (start_index...tokens.length).find { |i| tokens[i].type == :open_brace }
      end

      def deduplicate_cookware(cookware_items)
        # Group by name and prefer items with quantity over those without
        cookware_items.group_by(&:name).map do |_name, items|
          # Prefer items with quantity, then take the first one
          items.find(&:quantity) || items.first
        end
      end

      def remove_trailing_newlines(segments)
        # Remove trailing newlines and whitespace-only text segments
        segments.pop while segments.last == "\n" || (segments.last.is_a?(String) && segments.last.strip.empty?)
        segments
      end

      def extract_notes(tokens)
        notes = []
        content_tokens = []
        i = 0

        while i < tokens.length
          token = tokens[i]

          if token.type == :note_marker
            # Collect note content until newline
            note_content = ""
            i += 1

            while i < tokens.length && tokens[i].type != :newline
              note_content += tokens[i].value if tokens[i].type == :text
              i += 1
            end

            notes << Note.new(content: note_content.strip) unless note_content.strip.empty?

            # Skip the newline
            i + 1 if i < tokens.length && tokens[i].type == :newline
          else
            content_tokens << token
            i += 1
          end
        end

        [notes, content_tokens]
      end

      def extract_sections_and_steps(tokens)
        # For now, just return empty sections and use the original step splitting
        # This ensures backward compatibility while sections support is being implemented
        sections = []

        # Extract sections but don't group steps by them yet
        tokens.each_with_index do |token, i|
          next unless token.type == :section_marker

          # Parse section name
          section_name = ""
          j = i + 1

          # Collect text until another section marker or newline
          while j < tokens.length && tokens[j].type != :section_marker && tokens[j].type != :newline
            section_name += tokens[j].value if tokens[j].type == :text
            j += 1
          end

          section_name = section_name.strip
          section_name = nil if section_name.empty?

          # Create section (without steps for now)
          sections << Section.new(name: section_name, steps: []) if section_name
        end

        # Use original step splitting logic
        step_token_groups = split_into_steps(tokens)

        [sections, step_token_groups]
      end
  end
end
