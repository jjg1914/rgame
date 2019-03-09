require "dungeon/sdl"
require "dungeon/assets"

module Dungeon
  class VideoSystem
    WINDOW_FLAGS = SDL2::SDL_WINDOW_SHOWN |
                   SDL2::SDL_WINDOW_OPENGL
    RENDERER_FLAGS = SDL2::SDL_RENDERER_ACCELERATED |
                     SDL2::SDL_RENDERER_PRESENTVSYNC

    class VideoSystemInitError < StandardError; end

    class Context
      attr_accessor :color
      attr_accessor :alpha
      attr_accessor :scale

      def initialize renderer
        @renderer = renderer
        @color = 0x000000
        @alpha = 0xFF
        @rect = SDL2::SDL_Rect.new
        @rect_2 = SDL2::SDL_Rect.new
        @ints = FFI::MemoryPointer.new(:int, 8)
      end

      def [] key
        SDL2.SDL_GetHint(key.to_s)
      end

      def []= key, value
        SDL2.SDL_SetHint(key.to_s, value.to_s)
      end

      def color= value
        unless color == value
          SDL2.SDL_SetRenderDrawColor @renderer,
                                      value.red_value,
                                      value.green_value,
                                      value.blue_value,
                                      alpha
          @color = value
        end
      end

      def alpha= value
        unless alpha == value
          SDL2.SDL_SetRenderDrawColor @renderer,
                                      color.red_value,
                                      color.green_value,
                                      color.blue_value,
                                      value
          @alpha = value
        end
      end

      def scale= value
        value = [ value, value ] unless value.is_a? Array
        value = if value.empty?
          [ 1.0, 1.0 ]
        elsif value.size == 1
          [ value[0].to_f, value[0].to_f ]
        else
          value.take(2).map { |e| e.to_f }
        end

        unless scale == value
          SDL2.SDL_RenderSetScale @renderer, value[0], value[1]
          @scale = value
        end
      end

      def present
        SDL2.SDL_RenderPresent @renderer
      end

      def clear
        SDL2.SDL_RenderClear @renderer
      end

      def draw_rect x, y, w, h
        @rect[:x] = x
        @rect[:y] = y
        @rect[:w] = w
        @rect[:h] = h
        SDL2.SDL_RenderDrawRect(@renderer, @rect)
      end

      def fill_rect x, y, w, h
        @rect[:x] = x
        @rect[:y] = y
        @rect[:w] = w
        @rect[:h] = h
        SDL2.SDL_RenderFillRect(@renderer, @rect)
      end

      def draw_texture texture, x, y
        SDL2.SDL_QueryTexture(texture, nil, nil, @ints, @ints + 1)
        self.draw_sprite(texture, x, y, @ints.get(:int, 0), @ints.get(:int, 1), 0, 0)
      end

      def draw_sprite texture, x, y, x_offset, y_offset, width, height
        @rect[:x] = x
        @rect[:y] = y
        @rect[:w] = width
        @rect[:h] = height
        @rect_2[:x] = x_offset
        @rect_2[:y] = y_offset
        @rect_2[:w] = width
        @rect_2[:h] = height
        SDL2.SDL_RenderCopy(@renderer, texture, @rect_2, @rect)
      end
    end

    def self.open *args
      if block_given?
        video = self.open(*args)
        yield video
        video.close
      else
        self.new.tap { |o| o.open(*args) }
      end
    end
  
    def open title, width, height
      raise VideoSystemInitError if SDL2.SDL_Init(SDL2::SDL_INIT_VIDEO) != 0
      raise VideoSystemInitError if SDL2Image.IMG_Init(SDL2Image::IMG_INIT_PNG) == 0
      @window = SDL2.SDL_CreateWindow "test", 0, 0, width, height, WINDOW_FLAGS
      raise VideoSystemInitError if @window.nil?
      @renderer = SDL2.SDL_CreateRenderer @window, -1, RENDERER_FLAGS
      raise VideoSystemInitError if @renderer.nil?
    end

    def init_assets manifest
      Assets.init manifest, @renderer
    end

    def context
      (@context ||= Context.new @renderer)
    end
    
    def close
      SDL2.SDL_DestroyRenderer @renderer unless @renderer.nil?
      SDL2.SDL_DestroyWindow @window unless @window.nil?
      SDL2Image.IMG_Quit
      SDL2.SDL_Quit
    end
  end
end
