require "json"

module Dungeon
  module Core
    class Map
      attr_accessor :name
      attr_accessor :width
      attr_accessor :height
      attr_accessor :background
      attr_reader :entities

      class TiledMap < Dungeon::Core::Map
        def self.normalize_objectgroup json
          json["objects"].map do |e|
            e.dup.keep_if do |k,v|
              %w[type x y width height].include? k
            end.merge(Hash[*(e.fetch("properties", {}).map do |k,v|
              case e.fetch("propertytypes", {})[k].to_s.strip.downcase
              when "int"
                [ k, v.to_i ]
              when "float"
                [ k, v.to_f ]
              when "bool"
                [ k, !!v.to_i ]
              else
                [ k, v.to_s ]
              end
            end.flatten(1))])
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

        def self.load json
          self.new(json["width"] * json["tilewidth"],
                   json["height"] * json["tileheight"]).tap do |o|
            if /#([[:xdigit:]]{6})/ =~ json["backgroundcolor"]
              o.background = $~[1].to_i(16)
            end

            tileset = unless json["tilesets"].empty?
              File.basename(json["tilesets"].first["source"], ".json")
            end.to_s

            json["layers"].map do |e|
              case e["type"]
              when "imagelayer"
                self.normalize_imagelayer(e)
              when "tilelayer"
                unless tileset.empty?
                  self.normalize_tilelayer(e.merge({ "tileset" => tileset }))
                end
              when "objectgroup"
                self.normalize_objectgroup(e)
              end
            end.flatten(1).reject { |e| e.nil? }.each do |e|
              o.entities << e
            end
          end
        end
      end

      class DungeonMap < Dungeon::Core::Map
        def self.load json
          self.new(json["width"], json["height"]).tap do |o|
            o.background = json["background"]
            json["entities"].map { |e| o.entities << e }
          end
        end
      end

      def self.load_file filename
        name = File.basename(filename, ".json")
        data = JSON.parse File.read filename
        self.load(data).tap { |o| o.name = name }
      end

      def self.load json
        if json.has_key?("tiledversion")
          Dungeon::Core::Map::TiledMap.load(json)
        elsif json["meta"]["schema"] == "dungeon"
          Dungeon::Core::Map::DungeonMap.load(json)
        else
          raise "unknown map schema"
        end.tap { |o| o.name = name }
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
