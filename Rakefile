$:.unshift File.expand_path "lib", File.dirname(__FILE__)
require "dungeon/task"

Dungeon::Task.define

SDL2_SOURCE = "https://libsdl.org/release/SDL2-2.0.9.tar.gz"
SDL2_DEST = File.join("vendor", File.basename(SDL2_SOURCE))
SDL2_DIR = File.join("vendor", File.basename(SDL2_DEST, ".tar.gz"))
SDL2_PREFIX = File.expand_path(File.join("vendor", "SDL2"))

SDL2_IMAGE_SOURCE = "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.4.tar.gz"
SDL2_IMAGE_DEST = File.join("vendor", File.basename(SDL2_IMAGE_SOURCE))
SDL2_IMAGE_DIR = File.join("vendor", File.basename(SDL2_IMAGE_DEST, ".tar.gz"))
SDL2_IMAGE_PREFIX = File.expand_path(File.join("vendor", "SDL2"))

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
