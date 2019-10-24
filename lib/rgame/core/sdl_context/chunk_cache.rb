# frozen_string_literal: true

require "rgame/core/env"
require "rgame/core/sdl"
require "rgame/core/sdl_context/chunk"

module RGame
  module Core
    class SDLContext
      class ChunkCache < Hash
        def initialize
          super() { |h, k| h[k] = _impl_load(k) }
        end

        private

        def _impl_load value
          path = Env.sound_path.split(":").map do |e|
            File.expand_path("%s.wav" % value, e.strip)
          end.find do |e|
            File.exist?(e)
          end
          raise "sound not found %s" % value.inspect if path.nil?

          chunk = SDL2Mixer.Mix_LoadWAV_RW(SDL2.SDL_RWFromFile(path, "rb"), 1)
          Chunk.new(chunk).tap do |o|
            o.name = File.basename(value)
            o.path = path
          end
        end
      end
    end
  end
end
