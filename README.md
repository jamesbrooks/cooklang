# Cooklang

[![Test](https://github.com/jamesbrooks/cooklang/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/jamesbrooks/cooklang/actions/workflows/test.yml)
![Gem Version](https://img.shields.io/gem/v/cooklang)


A Ruby parser for the [Cooklang](https://cooklang.org) recipe markup language.

## Installation

Add to your Gemfile:

```ruby
gem 'cooklang'
```

Or install directly:

```bash
gem install cooklang
```

## Usage

```ruby
require 'cooklang'

recipe_text = <<~RECIPE
  >> title: Pancakes
  >> servings: 4

  Crack @eggs{3} into a bowl, add @flour{125%g} and @milk{250%ml}.

  Heat #frying pan over medium heat for ~{5%minutes}.
  Pour batter and cook until golden.
RECIPE

recipe = Cooklang.parse(recipe_text)

# Access metadata
recipe.metadata['title']        # => "Pancakes"
recipe.metadata['servings']     # => 4

# Access ingredients
recipe.ingredients.each do |ingredient|
  puts "#{ingredient.name}: #{ingredient.quantity} #{ingredient.unit}"
end
# => eggs: 3
# => flour: 125 g
# => milk: 250 ml

# Parse from file
recipe = Cooklang.parse_file('pancakes.cook')

# Format as text
formatter = Cooklang::Formatters::Text.new(recipe)
puts formatter.to_s
# Ingredients:
#     eggs        3
#     flour       125 g
#     milk        250 ml
#
# Steps:
#     1. Crack eggs into a bowl, add flour and milk.
#     2. Heat frying pan over medium heat for 5 minutes.
#     3. Pour batter and cook until golden.
```

## API

```ruby
# Recipe object
recipe.metadata         # Hash of metadata
recipe.ingredients      # Array of Ingredient objects
recipe.cookware         # Array of Cookware objects
recipe.timers           # Array of Timer objects
recipe.steps            # Array of Step objects
recipe.steps_text       # Array of plain text steps

# Ingredient
ingredient.name         # "flour"
ingredient.quantity     # 125
ingredient.unit         # "g"
ingredient.notes        # "sifted"

# Cookware
cookware.name          # "frying pan"
cookware.quantity      # 1

# Timer
timer.name            # "pasta"
timer.duration        # 10
timer.unit            # "minutes"
```

## Cooklang Syntax

- **Ingredients**: `@salt`, `@flour{125%g}`, `@onion{1}(diced)`
- **Cookware**: `#pan`, `#mixing bowl{}`
- **Timers**: `~{5%minutes}`, `~pasta{10%minutes}`
- **Comments**: `-- line comment`, `[- block comment -]`
- **Metadata**: `>> key: value` or YAML front matter

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop
```

## Resources

- [Cooklang Website](https://cooklang.org)
- [Language Specification](https://cooklang.org/docs/spec/)

## Contributing

Bug reports and pull requests welcome on GitHub.

## License

MIT License
