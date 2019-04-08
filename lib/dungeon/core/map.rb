require "json"

module Dungeon
  module Core
    class Map
      attr_reader :width
      attr_reader :height
      attr_reader :tile_width
      attr_reader :tile_height

      attr_reader :layers
      attr_reader :tileset

      attr_reader :background

      class Tilelayer
        attr_reader :data
        attr_reader :width
        attr_reader :height

        def self.from_json json
          self.new(json["height"].times.map do |j|
            json["width"].times.map do |i|
              offset = (j * json["width"]) + i
              json["data"][offset] - 1
            end
          end, json["width"], json["height"])
        end
    
        def initialize data, width, height
          @data = data
          @width = width
          @height = height
        end
      end

      def self.load filename
        data = JSON.parse File.read filename

        layers = data["layers"].map do |e|
          case e["type"]
          when "tilelayer"
            Tilelayer.from_json(e)
          end
        end

        tileset = File.basename(data["tilesets"].first["source"], ".json")

        background = if /#([[:xdigit:]]{6})/ =~ data["backgroundcolor"]
          $~[1].to_i(16)
        else
          0xAAAAAA
        end

        self.new(data["width"], data["height"],
                 data["tilewidth"], data["tileheight"],
                 layers, tileset, background)
      end

      def initialize width, height, tile_width, tile_height, layers, tileset, background
        @width = width
        @height = height
        @tile_width = tile_width
        @tile_height = tile_height
        @layers = layers
        @tileset = tileset
        @background = background
      end
    end
  end
end
