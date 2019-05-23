require "simplecov"
SimpleCov.start do
  add_filter "/test/"
end

require "minitest/autorun"
require 'minitest/reporters'
Minitest::Reporters.use!([
  Minitest::Reporters::SpecReporter.new(:color => true),
])
