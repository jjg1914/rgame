require "rake/testtask"
require 'rubocop/rake_task'
require 'yard'

$:.unshift File.expand_path "lib", File.dirname(__FILE__)

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.pattern = "test/unit/**/*_test.rb"
    t.libs = [ "lib", "test" ]
    t.ruby_opts = [ "-rtest_helper" ]
    t.verbose = true
  end

  Rake::TestTask.new(:integration) do |t|
    t.pattern = "test/integration/**/*_test.rb"
    t.libs = [ "lib", "test" ]
    t.ruby_opts = [ "-rtest_helper" ]
    t.verbose = true
  end
end

# define combined seperatly for single coverage report
Rake::TestTask.new(:test) do |t|
  t.pattern = "test/**/*_test.rb"
  t.libs = [ "lib", "test" ]
  t.ruby_opts = [ "-rtest_helper" ]
  t.verbose = true
end

RuboCop::RakeTask.new(:lint) do |task|
  task.patterns = [ 'lib/**/*.rb' ]
  # only show the files with failures
  #task.formatters = ['files']
  # don't abort rake on failure
  #task.fail_on_error = false
end

task :check => [ :test, :lint ]

YARD::Rake::YardocTask.new do |t|
 t.files = ['lib/**/*.rb']
end
