# frozen_string_literal: true

require "ffi"
require "rgame/core/sdl"

module RGame
  module Core
    class SDLContext
      class Texture
        attr_accessor :name
        attr_accessor :path
        attr_reader :texture
        attr_reader :width
        attr_reader :height

        def initialize texture
          @texture = texture

          mem_ints = 2.times.map { FFI::MemoryPointer.new(:int, 1) }
          SDL2.SDL_QueryTexture(texture, nil, nil, mem_ints[0], mem_ints[1])
          @width = mem_ints[0].get(:int, 0)
          @height = mem_ints[1].get(:int, 0)
        ensure
          mem_ints&.each { |e| e&.free }
        end

        def free
          return if @texture.nil?

          SDL2.SDL_DestroyTexture @texture
          @texture = nil
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def texture_blend_mode
          mem_int = FFI::MemoryPointer.new(:int, 1)
          SDL2.SDL_GetTextureBlendMode @texture, mem_int
          case mem_int.get(:int, 0)
          when SDL2::SDL_BLENDMODE_NONE
            "none"
          when SDL2::SDL_BLENDMODE_BLEND
            "blend"
          when SDL2::SDL_BLENDMODE_ADD
            "add"
          when SDL2::SDL_BLENDMODE_MOD
            "mod"
          else
            "invalid"
          end
        ensure
          mem_int.free unless mem_int.nil? or mem_int.null?
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def texture_blend_mode= value
          mode = case value
          when "none"
            SDL2::SDL_BLENDMODE_NONE
          when "blend"
            SDL2::SDL_BLENDMODE_BLEND
          when "add"
            SDL2::SDL_BLENDMODE_ADD
          when "mod"
            SDL2::SDL_BLENDMODE_MOD
          else
            SDL2::SDL_BLENDMODE_INVALID
          end

          SDL2.SDL_SetTextureBlendMode(@texture, mode)
        end
      end
    end
  end
end
