# frozen_string_literal: true

require "forwardable"
require "json"

module Dungeon
  module Core
    class Tileset
      extend Forwardable
      def_delegators :@image, :texture, :close

      attr_accessor :name

      attr_reader :tile_width
      attr_reader :tile_height

      class TileData
        attr_reader :x
        attr_reader :y

        def initialize x, y
          @x = x
          @y = y
        end

        def to_a
          [ @x, @y ]
        end
      end

      def self.load renderer, filename, name = "?"
        data = JSON.parse(File.read(filename))

        tiles = data["tilecount"].times.map do |i|
          x = i % data["columns"]
          y = i / data["columns"]

          TileData.new(x * data["tilewidth"],
                       y * data["tileheight"])
        end

        image_path = File.join(File.dirname(filename), data["image"])
        image = Dungeon::Core::Image.load(renderer, image_path)

        self.new(image, tiles, data["tilewidth"], data["tileheight"]).tap do |o|
          o.name = name
        end
      end

      def initialize image, tiles, tile_width, tile_height
        @image = image
        @tiles = tiles
        @tile_width = tile_width
        @tile_height = tile_height
      end

      def at index
        @tiles[index].to_a + [ @tile_width, @tile_height ]
      end
    end
  end
end
