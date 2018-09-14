# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'doorkeeper-jwt/version'

Gem::Specification.new do |spec|
  spec.name          = "doorkeeper-jwt"
  spec.version       = Doorkeeper::JWT::VERSION
  spec.authors       = ["Chris Warren"]
  spec.email         = ["chris@expectless.com"]

  spec.summary       = %q{JWT token generator for Doorkeeper}
  spec.description   = %q{JWT token generator extension for Doorkeeper}
  spec.homepage      = "https://github.com/chriswarren/doorkeeper-jwt"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jwt", "~> 2.1.0", ">= 2.1.0"

  spec.add_development_dependency "bundler", "~> 1.8", ">= 1.8"
  spec.add_development_dependency "rake", "~> 10.0", ">= 10.0"
  spec.add_development_dependency "rspec", "~> 3.2.0", ">= 3.2"
  spec.add_development_dependency "pry", "~> 0"
end
