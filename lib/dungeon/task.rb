# frozen_string_literal: true

require "pathname"
require "yaml"
require "json"

require "rake"
require "rake/tasklib"

module Dungeon
  class Task < Rake::TaskLib
    def self.define
      self.new.tap(&:define)
    end

    def self.xcf_to_png dest, source
      sh "convert %s -define png:color-type=2 %s" % [ source, dest ]
    end

    def self.ase_to_json dest, source
      FileUtils.cd(File.dirname(dest)) do
        sh([
          "aseprite",
          "-b", File.basename(source),
          "--sheet", File.basename(dest.ext(".png")),
          "--data", File.basename(dest),
          "--list-tags",
          "--format", "json-array",
        ].join(" "))
      end
    end

    def self.sources_to_manifest dest, sources
      base_dir = File.dirname File.expand_path dest
      base_dir_path = Pathname.new base_dir

      yaml = sources.map do |e|
        path = Pathname.new(File.expand_path(e))
                       .relative_path_from(base_dir_path)
                       .to_s

        ext_name = File.extname(path)

        {
          "name" => File.basename(e, ext_name),
          "path" => path,
          "type" => begin
          end,
        }
      end.to_yaml

      File.open(dest, "w") { |f| f.write yaml }
    end

    def self.asset_type_for_file path
      if `file -Ib #{path}`.chomp == "image/png; charset=binary"
        "png"
      elsif File.ext_name(path) == ".json"
        json = JSON.parse File.read e

        if json.is_a?(Hash) and json.key?("meta") and
           json["meta"].is_a?(Hash) and
           json["meta"]["app"] == "http://www.aseprite.org/"

          "sprite"
        elsif json.is_a?(Hash) and json.key?("meta") and
              json["meta"].is_a?(Hash) and
              json["meta"]["schema"] == "dungeon"

          "map"
        elsif json.is_a?(Hash) and json.key?("type")
          json["type"]
        else
          "?"
        end
      else
        "?"
      end
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
        Dungeon::Task.sources_to_manifest t.name, t.sources
      end

      rule ".json" => ".ase" do |t|
        Dungeon::Task.ase_to_json t.name, t.source
      end

      rule ".png" => ".xcf" do |t|
        Dungeon::Task.xcf_to_png t.name, t.source
      end
    end
  end
end
