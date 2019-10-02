# frozen_string_literal: true

require "coveralls"
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "doorkeeper/jwt"
require "pry"
