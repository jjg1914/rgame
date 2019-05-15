module Dungeon
  module Core
    class Image
      attr_accessor :name

      attr_reader :texture
      attr_reader :surface

      def self.load renderer, filename
        name = File.basename(filename, File.extname(filename))
        surface = SDL2Image.IMG_Load filename
        texture = SDL2.SDL_CreateTextureFromSurface renderer, surface

        self.new(texture, surface).tap do |o|
          o.name = name
        end
      end

      def initialize texture, surface
        @texture = texture
        @surface = surface
      end

      def close
        SDL2.SDL_FreeSurface @surface
        SDL2.SDL_DestroyTexture @texture
      end
    end
  end
end
