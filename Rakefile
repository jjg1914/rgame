require "yaml"
require "json"

SPRITE_SOURCES  = FileList["assets/sprites/*.ase"]
MAP_SOURCES     = FileList["assets/maps/*.json"]
TILESET_SOURCES = FileList["assets/tilesets/*.json"]
XCF_SOURCES     = FileList["assets/**/*.xcf"]

ASSET_SOURCES = SPRITE_SOURCES + MAP_SOURCES + TILESET_SOURCES

SDL2_SOURCE = "https://libsdl.org/release/SDL2-2.0.9.tar.gz"
SDL2_DEST = File.join("vendor", File.basename(SDL2_SOURCE))
SDL2_DIR = File.join("vendor", File.basename(SDL2_DEST, ".tar.gz"))
SDL2_PREFIX = File.expand_path(File.join("vendor", "SDL2"))

SDL2_IMAGE_SOURCE = "https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.4.tar.gz"
SDL2_IMAGE_DEST = File.join("vendor", File.basename(SDL2_IMAGE_SOURCE))
SDL2_IMAGE_DIR = File.join("vendor", File.basename(SDL2_IMAGE_DEST, ".tar.gz"))
SDL2_IMAGE_PREFIX = File.expand_path(File.join("vendor", "SDL2"))

task :assets => [ "assets/manifest.yaml" ] + XCF_SOURCES.ext(".png")

task :vendor => [ :vendor_sdl, :vendor_sdl_image ]

task :clean do
  FileUtils.rm(SPRITE_SOURCES.ext(".json") +
    SPRITE_SOURCES.ext(".png") +
    XCF_SOURCES.ext(".png"))
end

file "assets/manifest.yaml" => ASSET_SOURCES.ext(".json") do |t|
  File.open(t.name, "w") do |f|
    f.write(t.sources.map do |e|
      {
        "name" => File.basename(e, ".json"),
        "path" => e,
        "type" => begin
          json = JSON.parse File.read e

          if json.is_a?(Hash) and json.has_key?("meta") and
            json["meta"].is_a?(Hash) and 
            json["meta"]["app"] == "http://www.aseprite.org/"

            "sprite"
          elsif json.is_a?(Hash) and json.has_key?("type")
            json["type"]
          else
            "?"
          end
        end,
      }
    end.to_yaml)
  end
end

rule ".json" => ".ase" do |t|
  sh "aseprite -b %s --sheet %s --data %s --list-tags --format json-array" % [
    t.source,
    t.name.ext(".png"),
    t.name,
  ]
end

rule ".png" => ".xcf" do |t|
  sh "convert %s %s" % [ t.name, t.source ]
end

task :vendor_sdl => [ SDL2_DIR ] do |t|
  FileUtils.mkdir_p File.join(t.source, "build")
  FileUtils.cd(File.join(t.source, "build")) do
    sh "../configure --prefix=%s" % [ SDL2_PREFIX.inspect ]
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

file SDL2_IMAGE_DIR => SDL2_IMAGE_DEST do |t|
  sh "tar -xz -C %s -f %s" % [ File.dirname(t.source), t.source ]
end

file(SDL2_IMAGE_DEST) do |t|
  sh "mkdir -p %s" % File.dirname(t.name)
  sh "curl -o %s %s" % [ t.name, SDL2_IMAGE_SOURCE ]
end
