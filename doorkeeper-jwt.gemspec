# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "doorkeeper/jwt/version"

Gem::Specification.new do |spec|
  spec.name = "doorkeeper-jwt"
  spec.version = Doorkeeper::JWT.gem_version
  spec.authors = ["Chris Warren", "Nikita Bulai"]
  spec.email = ["chris@expectless.com"]

  spec.summary = "JWT token generator for Doorkeeper"
  spec.description = "JWT token generator extension for Doorkeeper"
  spec.homepage = "https://github.com/chriswarren/doorkeeper-jwt"
  spec.license = "MIT"

  spec.bindir = "exe"
  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "jwt", "~> 2.2"

  spec.add_development_dependency "bundler", ">= 1.16", "< 3"
  spec.add_development_dependency "pry", "~> 0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.8"
end
