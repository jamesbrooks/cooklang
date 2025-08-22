# frozen_string_literal: true

require_relative "lib/cooklang/version"

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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml]) ||
        f.match?(%r{\A(Rakefile)\z})
    end
  end
  spec.bindir = "exe"
  spec.executables = []
  spec.require_paths = ["lib"]
end
