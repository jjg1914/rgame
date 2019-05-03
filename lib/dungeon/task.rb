require "pathname"
require "yaml"
require "json"

require 'rake'
require 'rake/tasklib'

module Dungeon
  class Task < Rake::TaskLib
    def self.define
      self.new.tap { |o| o.define }
    end

    def define
      sprite_sources   = FileList["assets/sprites/*.ase"]
      map_sources      = FileList["assets/maps/*.json"]
      tileset_sources  = FileList["assets/tilesets/*.json"]
      xcf_sources      = FileList["assets/**/*.xcf"]

      manifest_sources = sprite_sources.ext(".json") +
                         map_sources +
                         tileset_sources +
                         xcf_sources.ext(".png")

      task :assets => [ "assets/manifest.yaml" ]

      task :clean_assets do
        rm_f sprite_sources.ext(".json")
        rm_f sprite_sources.ext(".png")
        rm_f xcf_sources.ext(".png")
        rm_f "assets/manifest.yaml"
      end

      file "assets/manifest.yaml" => manifest_sources do |t|
        base_dir = File.dirname File.expand_path t.name
        base_dir_path = Pathname.new base_dir

        yaml = t.sources.map do |e|
          path = Pathname.new(File.expand_path e).
            relative_path_from(base_dir_path).
            to_s

          ext_name = File.extname(path)

          {
            "name" => File.basename(e, ext_name),
            "path" => path,
            "type" => begin
              if `file -Ib #{e}`.chomp == "image/png; charset=binary"
                "png"
              elsif ext_name == ".json"
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
              else
                "?"
              end
            end,
          }
        end.to_yaml

        File.open(t.name, "w") { |f| f.write yaml }
      end

      rule ".json" => ".ase" do |t|
        FileUtils.cd(File.dirname(t.name)) do
          sh "aseprite -b %s --sheet %s --data %s --list-tags --format json-array" % [
            File.basename(t.source),
            File.basename(t.name.ext(".png")),
            File.basename(t.name),
          ]
        end
      end

      rule ".png" => ".xcf" do |t|
        sh "convert %s -define png:color-type=2 %s" % [ t.source, t.name ]
      end
    end
  end
end
