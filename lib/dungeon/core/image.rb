module Dungeon
  module Core
    class Image
      attr_reader :texture
      attr_reader :surface

      def self.load renderer, filename
        surface = SDL2Image.IMG_Load filename
        texture = SDL2.SDL_CreateTextureFromSurface renderer, surface

        self.new(texture, surface)
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
