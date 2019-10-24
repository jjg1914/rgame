# frozen_string_literal: true

require "rgame/core/sdl"

module RGame
  module Core
    class SDLContext
      class Renderer
        module FontMethods
          attr_accessor :font

          private

          def font_pointer
            font_cache[@font] unless @font.nil?
          end

          def fc_font_pointer color, alpha
            fc_font_cache[[ @font, color, alpha ]] unless @font.nil?
          end

          def font_cache
            @font_cache ||= TTFFontCache.new
          end

          def fc_font_cache
            @fc_font_cache ||= FCFontCache.new @renderer
          end
        end

        module ColorMethods
          attr_reader :color
          attr_reader :alpha

          def color= value
            return if @color == value

            color_struct.assign_rgb_a value.to_i, alpha.to_i
            SDL2.SDL_SetRenderDrawColor @renderer,
                                        color_struct[:r],
                                        color_struct[:g],
                                        color_struct[:b],
                                        color_struct[:a]
            @color = value
          end

          def alpha= value
            return if @alpha == value

            color_struct.assign_rgb_a color.to_i, value.to_i
            SDL2.SDL_SetRenderDrawColor @renderer,
                                        color_struct[:r],
                                        color_struct[:g],
                                        color_struct[:b],
                                        color_struct[:a]

            @alpha = value
          end

          private

          def color_struct
            @color_struct ||= SDL2::SDLColor.new
          end
        end

        module ScaleMethods
          attr_reader :scale
          attr_reader :scale_quality

          def scale= value
            value = [ value, value ] unless value.is_a? Array
            value = if value.empty?
              [ 1.0, 1.0 ]
            elsif value.size == 1
              [ value[0].to_f, value[0].to_f ]
            else
              value.take(2).map(&:to_f)
            end

            return if @scale == value

            SDL2.SDL_RenderSetScale @renderer, value[0], value[1]
            @scale = value
          end

          def scale_quality= value
            return if @scale_quality == value

            value = case value.to_s.strip.downcase
            when "linear"
              "1"
            when "best"
              "2"
            else
              "0"
            end
            SDL2.SDL_SetHint(SDL2::SDL_HINT_RENDER_SCALE_QUALITY, value)
            @scale_quality = value
          end
        end

        module TextureMethods
          attr_reader :source
          attr_reader :target

          def source= value
            @source = if value.is_a? Texture
              value
            else
              texture_cache[value.to_s]
            end
          end

          def target= value
            return if @target == value

            SDL2.SDL_SetRenderTarget(@renderer, value&.texture)
            @target = value
          end

          private

          def texture_cache
            @texture_cache ||= TextureCache.new @renderer
          end
        end

        include FontMethods
        include ColorMethods
        include ScaleMethods
        include TextureMethods

        attr_reader :clip_bounds

        def initialize renderer
          @renderer = renderer

          @color = -1
          @alpha = -1
          @scale = -1
          @scale_quality =
            SDL2.SDL_GetHint(SDL2::SDL_HINT_RENDER_SCALE_QUALITY)
          self.color = 0x000000
          self.alpha = 0xFF
          self.scale = 1
          self.scale_quality = "best"

          @sdl_rects = 2.times.map { SDL2::SDLRect.new }
          @mem_ints = 8.times.map { FFI::MemoryPointer.new(:int, 1) }
        end

        def present
          SDL2.SDL_RenderPresent @renderer
        end

        def clear
          SDL2.SDL_RenderClear @renderer
        end

        def stroke_rect x, y, width, height
          @sdl_rects[0][:x] = x
          @sdl_rects[0][:y] = y
          @sdl_rects[0][:w] = width
          @sdl_rects[0][:h] = height
          SDL2.SDL_RenderDrawRect(@renderer, @sdl_rects[0])
        end

        def fill_rect x, y, width, height
          @sdl_rects[0][:x] = x
          @sdl_rects[0][:y] = y
          @sdl_rects[0][:w] = width
          @sdl_rects[0][:h] = height
          SDL2.SDL_RenderFillRect(@renderer, @sdl_rects[0])
        end

        def draw_image x, y, dx = 0, dy = 0, width = nil, height = nil
          return if @source.nil?

          @sdl_rects[0][:x] = x
          @sdl_rects[0][:y] = y
          @sdl_rects[0][:w] = width || @source.width
          @sdl_rects[0][:h] = height || @source.height
          @sdl_rects[1][:x] = dx
          @sdl_rects[1][:y] = dy
          @sdl_rects[1][:w] = width || @source.width
          @sdl_rects[1][:h] = height || @source.height
          SDL2.SDL_RenderCopy(@renderer,
                              @source.texture,
                              @sdl_rects[1],
                              @sdl_rects[0])
        end

        def draw_text text, x, y
          ptr = fc_font_pointer(self.color, self.alpha)
          return if ptr.nil? or ptr.null?

          SDLFontCache.FC_Draw ptr, @renderer, x, y, text
        end

        def create_image width, height
          format = if @window.nil?
            SDL2::SDL_PIXELFORMAT_ARGB8888
          else
            SDL2.SDL_GetWindowPixelFormat(@window)
          end
          texture = SDL2.SDL_CreateTexture(@renderer, format,
                                           SDL2::SDL_TEXTUREACCESS_TARGET,
                                           width, height)
          Texture.new texture
        end

        def create_text text
          return if font_pointer.nil? or font_pointer.null?

          surface = SDL2TTF.TTF_RenderText_Solid font_pointer,
                                                 text,
                                                 color_struct
          texture = SDL2.SDL_CreateTextureFromSurface(@renderer, surface)
          SDL2.SDL_FreeSurface(surface)

          Texture.new texture
        end

        def size_of_text text
          if font_pointer.nil? or font_pointer.null?
            [ 0, 0 ]
          else
            SDL2TTF.TTF_SizeText(font_pointer,
                                 text, @mem_ints[0], @mem_ints[1])
            [ @mem_ints[0].get(:int, 0), @mem_ints[1].get(:int, 0) ]
          end
        end

        def clip_bounds= value
          return if @clip_bounds == value

          if value.nil?
            SDL2.SDL_RenderSetClipRect @renderer, nil
          else
            @sdl_rects[0][:x] = value["left"]
            @sdl_rects[0][:y] = value["top"]
            @sdl_rects[0][:w] = value["right"] - value["left"] + 1
            @sdl_rects[0][:h] = value["bottom"] - value["top"] + 1

            SDL2.SDL_RenderSetClipRect @renderer, @sdl_rects[0]
          end

          @clip_bounds = value
        end
      end
    end
  end
end
