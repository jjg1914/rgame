require "simplecov"
require "simplecov-cobertura"
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

module Minitest::Spec::DSL
  def stash_env name
    before do
      self.instance_variable_set("@_old_%s" % name.downcase, ENV[name])
    end

    after do
      val = self.instance_variable_get("@_old_%s" % name.downcase)
      if val.nil?
        ENV.delete name
      else
        ENV[name] = val
      end
    end
  end
end
