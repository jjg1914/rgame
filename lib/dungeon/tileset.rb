require 'forwardable'
require "json"

require "dungeon/image"

module Dungeon
  class Tileset
    extend Forwardable
    def_delegators :@image, :texture, :close

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

    def self.load renderer, filename
      data = JSON.parse(File.read filename)

      tiles = data["tilecount"].times.map do |i|
        x = i % data["columns"]
        y = i / data["columns"]

        TileData.new(x * data["tilewidth"],
                     y * data["tileheight"])
      end

      image_path = File.join(File.dirname(filename), data["image"])
      image = Dungeon::Image.load(renderer, image_path)

      self.new(image, tiles, data["tilewidth"], data["tileheight"])
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
