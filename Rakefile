require "rake/testtask"
require 'rubocop/rake_task'

$:.unshift File.expand_path "lib", File.dirname(__FILE__)

ENV["LD_LIBRARY_PATH"] = [
  File.expand_path("vendor/SDL2/lib", File.dirname(__FILE__)),
  ENV["LD_LIBRARY_PATH"],
].join(":")

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
  t.libs = [ "lib", "test" ]
  t.ruby_opts = [ "-rtest_helper" ]
  t.verbose = true
end

RuboCop::RakeTask.new(:lint) do |task|
  #task.patterns = [ 'lib/**/*.rb' ]
  task.patterns = [ 'lib/dungeon/task.rb', 'lib/dungeon/core/*.rb' ]
  # only show the files with failures
  #task.formatters = ['files']
  # don't abort rake on failure
  #task.fail_on_error = false
end

SDL2_SOURCE = "https://libsdl.org/release/SDL2-2.0.9.tar.gz"
SDL2_DEST = File.join("vendor", File.basename(SDL2_SOURCE))
SDL2_DIR = File.join("vendor", File.basename(SDL2_DEST, ".tar.gz"))
SDL2_PREFIX = File.expand_path(File.join("vendor", "SDL2"))

SDL2_IMAGE_SOURCE = "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.4.tar.gz"
SDL2_IMAGE_DEST = File.join("vendor", File.basename(SDL2_IMAGE_SOURCE))
SDL2_IMAGE_DIR = File.join("vendor", File.basename(SDL2_IMAGE_DEST, ".tar.gz"))
SDL2_IMAGE_PREFIX = File.expand_path(File.join("vendor", "SDL2"))

SDL2_TTF_SOURCE = "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.15.tar.gz"
SDL2_TTF_DEST = File.join("vendor", File.basename(SDL2_TTF_SOURCE))
SDL2_TTF_DIR = File.join("vendor", File.basename(SDL2_TTF_DEST, ".tar.gz"))
SDL2_TTF_PREFIX = File.expand_path(File.join("vendor", "SDL2"))

task :vendor => [ :vendor_sdl, :vendor_sdl_image ]

task :vendor_sdl => [ SDL2_DIR ] do |t|
  FileUtils.mkdir_p File.join(t.source, "build")
  FileUtils.cd(File.join(t.source, "build")) do
    sh "../configure --prefix=%s" % [ SDL2_PREFIX.inspect ]
    sh "make install"
  end
end

task :vendor_sdl_image => [ SDL2_IMAGE_DIR ] do |t|
  FileUtils.mkdir_p File.join(t.source, "build")
  FileUtils.cd(File.join(t.source, "build")) do
    sh "SDL2_CONFIG=%s ../configure %s" % [ 
      File.join(SDL2_PREFIX, "bin/sdl2-config"),
      [
        "--disable-dependency-tracking",
        "--prefix=" + SDL2_IMAGE_PREFIX.inspect,
        "--disable-imageio",
        "--disable-jpg-shared",
        "--disable-png-shared",
        "--disable-tif-shared",
        "--disable-webp-shared",
      ].join(" "),
    ]
    sh "make install"
  end
end

task :vendor_sdl_ttf=> [ SDL2_TTF_DIR ] do |t|
  FileUtils.mkdir_p File.join(t.source, "build")
  FileUtils.cd(File.join(t.source, "build")) do
    sh "SDL2_CONFIG=%s ../configure %s" % [ 
      File.join(SDL2_PREFIX, "bin/sdl2-config"),
      [
        "--prefix=" + SDL2_IMAGE_PREFIX.inspect,
        "--disable-static",
      ].join(" "),
    ]
    sh "make install"
  end
end

file SDL2_DIR => SDL2_DEST do |t|
  sh "tar -xz -C %s -f %s" % [ File.dirname(t.source), t.source ]
end

file(SDL2_DEST) do |t|
  sh "mkdir -p %s" % File.dirname(t.name)
  sh "curl -o %s %s" % [ t.name, SDL2_SOURCE ]
end

file SDL2_IMAGE_DIR => SDL2_IMAGE_DEST do |t|
  sh "tar -xz -C %s -f %s" % [ File.dirname(t.source), t.source ]
end

file(SDL2_IMAGE_DEST) do |t|
  sh "mkdir -p %s" % File.dirname(t.name)
  sh "curl -o %s %s" % [ t.name, SDL2_IMAGE_SOURCE ]
end

file SDL2_TTF_DIR => SDL2_TTF_DEST do |t|
  sh "tar -xz -C %s -f %s" % [ File.dirname(t.source), t.source ]
end

file(SDL2_TTF_DEST) do |t|
  sh "mkdir -p %s" % File.dirname(t.name)
  sh "curl -o %s %s" % [ t.name, SDL2_TTF_SOURCE ]
end
