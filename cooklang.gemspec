# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cooklang/version"

Gem::Specification.new do |spec|
  spec.name = "cooklang"
  spec.version = Cooklang::VERSION
  spec.authors = ["James Brooks"]
  spec.email = ["james@jamesbrooks.net"]

  spec.summary = "A Ruby parser for the Cooklang recipe markup language."
  spec.description = "Cooklang is a markup language for recipes that allows you to define ingredients, cookware, timers, and metadata in a structured way. This gem provides a Ruby parser for Cooklang files."
  spec.homepage = "https://github.com/jamesbrooks/cooklang"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jamesbrooks/cooklang"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.7"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.80"
  spec.add_development_dependency "rubocop-performance", "~> 1.25"
  spec.add_development_dependency "rubocop-rspec", "~> 3.6"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
end
