require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'doorkeeper-jwt'
require 'pry'

require 'coveralls'
Coveralls.wear!
