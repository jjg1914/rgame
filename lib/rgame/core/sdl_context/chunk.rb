# frozen_string_literal: true

require "rgame/core/sdl"

module RGame
  module Core
    class SDLContext
      class Chunk
        attr_accessor :name
        attr_accessor :path
        attr_reader :chunk

        def initialize chunk
          @chunk = chunk
        end

        def free
          return if @chunk.nil?

          SDL2Mixer.Mix_FreeChunk @chunk
          @chunk = nil
        end
      end
    end
  end
end
