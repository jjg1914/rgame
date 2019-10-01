require "simplecov"
require "simplecov-cobertura"
require "codecov"
SimpleCov.start do
  add_filter "/test/"
  if ENV.key? "CODECOV_TOKEN"
    self.formatters = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::CoberturaFormatter,
      SimpleCov::Formatter::Codecov,
    ])
  else
    self.formatters = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::CoberturaFormatter,
    ])
  end
end

require "minitest/autorun"
require 'minitest/reporters'
Minitest::Reporters.use!([
  Minitest::Reporters::SpecReporter.new(:color => true),
])
