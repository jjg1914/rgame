# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "rgame"
  s.version     = "0.1.0"
  s.summary     = "rgame"
  s.description = "rgame"
  s.authors     = [ "John J. Glynn IV" ]
  s.email       = "jjg1914@gmail.com"
  s.files       = Dir["lib/**/*"]
  s.homepage    = "https://github.com/jjg1914/rgame"
  s.metadata    = {
    "source_code_uri" => "https://github.com/jjg1914/rgame",
  }

  s.add_runtime_dependency "ffi"
  s.add_runtime_dependency "dotenv"
  s.add_runtime_dependency "thor"
end
