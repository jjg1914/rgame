require "simplecov"
require "simplecov-cobertura"
require "codecov"
SimpleCov.start do
  add_filter "/test/"
  self.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter,
  ])
end

require "minitest/autorun"
require 'minitest/reporters'
Minitest::Reporters.use!([
  Minitest::Reporters::SpecReporter.new(:color => true),
])
