# frozen_string_literal: true

require "json"
require "dungeon/core/env"

module Dungeon
  module Core
    class Map
      attr_accessor :name
      attr_accessor :path

      attr_accessor :width
      attr_accessor :height
      attr_accessor :background
      attr_reader :entities

      class TiledMap < Dungeon::Core::Map
        def self.normalize_objectgroup json
          json["objects"].map do |e|
            e.dup.keep_if do |k, _v|
              %w[type x y width height].include? k
            end.merge(e.fetch("properties", {}).map do |k, v|
              case e.fetch("propertytypes", {})[k].to_s.strip.downcase
              when "int"
                [ k, v.to_i ]
              when "float"
                [ k, v.to_f ]
              when "bool"
                [ k, v.to_i != 0 ]
              else
                [ k, v.to_s ]
              end
            end.to_h)
          end
        end

        def self.normalize_tilelayer json
          {
            "type" => "dungeon::common::tilelayer",
            "data" => json["height"].times.map do |j|
              json["width"].times.map do |i|
                offset = (j * json["width"]) + i
                json["data"][offset] - 1
              end
            end,
            "tileset" => json["tileset"],
          }
        end

        def self.normalize_imagelayer json
          ext_name = File.extname(json["image"])
          {
            "type" => "dungeon::common::imagelayer",
            "image" => File.basename(json["image"], ext_name),
          }
        end

        def self.normalize_layer json, parent
          case json["type"]
          when "imagelayer"
            self.normalize_imagelayer(json)
          when "tilelayer"
            tileset = unless parent["tilesets"].empty?
              File.basename(parent["tilesets"].first["source"], ".json")
            end.to_s

            unless tileset.empty?
              self.normalize_tilelayer(json.merge({ "tileset" => tileset }))
            end
          when "objectgroup"
            self.normalize_objectgroup(json)
          end
        end

        def self.load_json json
          self.new(json["width"] * json["tilewidth"],
                   json["height"] * json["tileheight"]).tap do |o|
            if /#([[:xdigit:]]{6})/ =~ json["backgroundcolor"]
              o.background = $~[1].to_i(16)
            end

            json["layers"].map do |e|
              normalize_layer(e, json)
            end.flatten(1).reject(&:nil?).each do |e|
              o.entities << e
            end
          end
        end
      end

      class DungeonMap < Dungeon::Core::Map
        def self.load_json json
          self.new(json["width"], json["height"]).tap do |o|
            o.background = json["background"]
            json["entities"].map { |e| o.entities << e }
          end
        end
      end

      def self.find_path_for name
        Env.map_path.split(File::PATH_SEPARATOR).map do |e|
          File.expand_path("%s.json" % name, e)
        end.find do |e|
          File.exist? e
        end
      end

      def self.load name
        path = find_path_for(name)
        raise "map not found %s" % name.inspect if path.nil?

        data = JSON.parse File.read path
        self.load_json(data).tap do |o|
          o.name = File.basename name
          o.path = path
        end
      end

      def self.load_json json
        if json.key?("tiledversion")
          Dungeon::Core::Map::TiledMap.load_json(json)
        elsif json.dig("meta", "schema") == "dungeon"
          Dungeon::Core::Map::DungeonMap.load_json(json)
        else
          raise "unknown map schema"
        end
      end

      def initialize width, height
        @width = width
        @height = height
        @entities = []
        @background = 0xAAAAAA
      end
    end
  end
end
