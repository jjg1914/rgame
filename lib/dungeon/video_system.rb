require "dungeon/sdl"

module Dungeon
  class VideoSystem
    WINDOW_FLAGS = SDL2::SDL_WINDOW_SHOWN | SDL2::SDL_WINDOW_OPENGL
    RENDERER_FLAGS = SDL2::SDL_RENDERER_ACCELERATED

    class VideoSystemInitError < StandardError; end

    class Context
      attr_accessor :color
      attr_accessor :alpha

      def initialize renderer
        @renderer = renderer
        @color = 0x000000
        @alpha = 0xFF
        @rect = SDL2::SDL_Rect.new
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
      @window = SDL2.SDL_CreateWindow "test", 0, 0, width, height, WINDOW_FLAGS
      raise VideoSystemInitError if @window.nil?
      @renderer = SDL2.SDL_CreateRenderer @window, -1, RENDERER_FLAGS
      raise VideoSystemInitError if @renderer.nil?
    end

    def context
      (@context ||= Context.new @renderer)
    end
    
    def close
      SDL2.SDL_DestroyRenderer @renderer unless @renderer.nil?
      SDL2.SDL_DestroyWindow @window unless @window.nil?
      SDL2.SDL_Quit
    end
  end
end
