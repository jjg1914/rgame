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

    def define
      sprite_sources   = FileList["assets/sprites/*.ase"]
      map_sources      = FileList["assets/maps/*.json"]
      tileset_sources  = FileList["assets/tilesets/*.json"]
      xcf_sources      = FileList["assets/**/*.xcf"]

      manifest_sources = sprite_sources.ext(".json") +
                         map_sources +
                         tileset_sources +
                         xcf_sources.ext(".png")

      task :assets => manifest_sources

      task :clean_assets do
        rm_f sprite_sources.ext(".json")
        rm_f sprite_sources.ext(".png")
        rm_f xcf_sources.ext(".png")
        rm_f "assets/manifest.yaml"
      end

      rule ".json" => ".ase" do |t|
        FileUtils.cd(File.dirname(t.name)) do
          sh([
            "aseprite",
            "-b", File.basename(t.source),
            "--sheet", File.basename(t.name.ext(".png")),
            "--data", File.basename(t.name),
            "--list-tags",
            "--format", "json-array",
          ].join(" "))
        end
      end

      rule ".png" => ".xcf" do |t|
        sh "convert %s -define png:color-type=2 %s" % [ t.source, t.name ]
      end
    end
  end
end
