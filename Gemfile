# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in doorkeeper-jwt.gemspec
gemspec

# Pin Doorkeeper to check a specific version of it against this gem. Unset means
# "the newest version the gemspec allows"; CI sets it to both ends of the
# supported range. See .github/workflows/ci.yml.
doorkeeper_version = ENV.fetch("DOORKEEPER_VERSION", "latest")
gem "doorkeeper", doorkeeper_version unless doorkeeper_version == "latest"

gem "simplecov", "~> 1.1", require: false
gem "rubocop", "~> 1.8", require: false
gem "rubocop-rspec", "~> 3.0", require: false
