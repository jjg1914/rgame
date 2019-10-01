require "simplecov"
require "codecov"
SimpleCov.start do
  add_filter "/test/"
  if ENV.key? "CODECOV_TOKEN"
    self.formatters = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Codecov
    ])
  end
end

require "minitest/autorun"
require 'minitest/reporters'
Minitest::Reporters.use!([
  Minitest::Reporters::SpecReporter.new(:color => true),
])
