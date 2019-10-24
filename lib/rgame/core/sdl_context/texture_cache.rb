# frozen_string_literal: true

require "rgame/core/env"
require "rgame/core/sdl"
require "rgame/core/sdl_context/texture"

module RGame
  module Core
    class SDLContext
      class TextureCache < Hash
        def initialize renderer
          super() { |h, k| h[k] = _impl_load(k) }
          @renderer = renderer
        end

        private

        def _impl_load value
          path = Env.image_path.split(":").map do |e|
            File.expand_path("%s.png" % value, e.strip)
          end.find do |e|
            File.exist?(e)
          end
          raise "image not found %s" % value.inspect if path.nil?

          surface = SDL2Image.IMG_Load path
          texture = SDL2.SDL_CreateTextureFromSurface @renderer, surface

          Texture.new(texture).tap do |o|
            SDL2.SDL_FreeSurface surface
            o.name = File.basename(value)
            o.path = path
          end
        end
      end
    end
  end
end
