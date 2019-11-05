# frozen_string_literal: true

require "forwardable"
require "fcntl"

require "rgame/core/env"
require "rgame/core/events"
require "rgame/core/sdl"
require "rgame/core/sdl_context/event_source"
require "rgame/core/sdl_context/texture_cache"
require "rgame/core/sdl_context/ttf_font_cache"
require "rgame/core/sdl_context/fc_font_cache"
require "rgame/core/sdl_context/chunk_cache"
require "rgame/core/sdl_context/texture"
require "rgame/core/sdl_context/renderer"
require "rgame/core/sdl_context/mixer"
require "rgame/core/sdl_context/state_saver"

module RGame
  module Core
    class SDLContext
      WINDOW_FLAGS = SDL2::SDL_WINDOW_SHOWN |
                     SDL2::SDL_WINDOW_OPENGL
      RENDERER_FLAGS = SDL2::SDL_RENDERER_ACCELERATED |
                       SDL2::SDL_RENDERER_PRESENTVSYNC

      class SDLBaseContext
        extend Forwardable
        def_delegators :@stack, :save, :restore

        attr_reader :events
        attr_reader :mixer
        attr_reader :renderer

        def initialize sdl_flags
          _init_sdl sdl_flags

          yield if block_given?

          @events = EventSource.new
          @mixer = Mixer.new
          @renderer = Renderer.new @sdl_renderer
          @stack = StateSaver.new([
            [ @renderer, "target" ],
            [ @renderer, "source" ],
            [ @renderer, "color" ],
            [ @renderer, "alpha" ],
            [ @renderer, "scale" ],
            [ @renderer, "scale_quality" ],
            [ @renderer, "font" ],
            [ @renderer, "clip_bounds" ],
            [ @events, "text_input_mode" ],
            [ @mixer, "channel" ],
            [ @mixer, "max_channels" ],
          ])
        end

        def close
          SDL2.SDL_DestroyRenderer @sdl_renderer unless @sdl_renderer.nil?
          SDL2Mixer.Mix_CloseAudio
          SDL2TTF.TTF_Quit
          SDL2Image.IMG_Quit
          SDL2.SDL_Quit
        end

        private

        def _init_sdl sdl_flags
          raise SDL2.SDL_GetError unless SDL2.SDL_Init(sdl_flags).zero?

          if SDL2Image.IMG_Init(SDL2Image::IMG_INIT_PNG).zero?
            raise SDL2.SDL_GetError
          end

          if not (sdl_flags & SDL2::SDL_INIT_AUDIO).zero? and
             SDL2Mixer.Mix_OpenAudio(44_100,
                                     SDL2Mixer::MIX_DEFAULT_FORMAT,
                                     1, 2048).negative?
            raise SDL2.SDL_GetError
          end

          raise SDL2.SDL_GetError unless SDL2TTF.TTF_Init.zero?
        end
      end

      class SDLWindowContext < SDLBaseContext
        def initialize title, width, height
          super(SDL2::SDL_INIT_VIDEO | SDL2::SDL_INIT_AUDIO) do
            @window = SDL2.SDL_CreateWindow title, 0, 0,
                                            width, height,
                                            WINDOW_FLAGS
            raise SDL2.SDL_GetError if @window.nil?

            @sdl_renderer = SDL2.SDL_CreateRenderer @window, -1, RENDERER_FLAGS
            raise SDL2.SDL_GetError if @sdl_renderer.nil?
          end
        end

        def dimensions
          mem = FFI::MemoryPointer.new(:int, 2)
          SDL2.SDL_GetWindowSize @window, mem, mem + 4
          [ mem.get(:int, 0), mem.get(:int, 4) ]
        ensure
          mem.free
        end

        def close
          SDL2.SDL_DestroyWindow @window unless @window.nil?
          super
        end
      end

      class SDLSoftwareContext < SDLBaseContext
        def initialize width, height
          super(0) do
            surface_flags = SDL2::SDL_PIXELFORMAT_ARGB8888
            @surface = SDL2.SDL_CreateRGBSurfaceWithFormat 0,
                                                           width, height, 32,
                                                           surface_flags

            raise SDL2.SDL_GetError if @surface.nil?

            @sdl_renderer = SDL2.SDL_CreateSoftwareRenderer @surface
            raise SDL2.SDL_GetError if @sdl_renderer.nil?
          end
        end

        def dimensions
          [ @surface[:w], @surface[:h] ]
        end

        def read_bytes
          size = @surface[:w] * @surface[:h] * 4
          @surface[:pixels].read_bytes(size)
        end

        def close
          SDL2.SDL_FreeSurface @surface unless @surface.nil?
          super
        end
      end

      class SDLMmapContext < SDLBaseContext
        def initialize filename, width, height
          super(0) do
            data, @io = _create_mmap filename, width, height
            @surface = SDL2.SDL_CreateRGBSurfaceFrom data, width, height,
                                                     32, 4 * width,
                                                     0xFF000000,
                                                     0xFF0000,
                                                     0xFF00,
                                                     0xFF
            raise SDL2.SDL_GetError if @surface.nil?

            @sdl_renderer = SDL2.SDL_CreateSoftwareRenderer @surface
            raise SDL2.SDL_GetError if @sdl_renderer.nil?
          end
        end

        def dimensions
          [ @surface[:w], @surface[:h] ]
        end

        def close
          data = @surface[:pixels]
          length = @surface[:w] * @surface[:h] * 4
          pagesize = Internal.getpagesize
          mmap_length = ((length / pagesize) + 1) * pagesize

          SDL2.SDL_FreeSurface @surface unless @surface.nil?
          Internal.munmap(data, mmap_length)
          Internal.shm_unlink @io.path
          @io.close
        end

        private

        def _create_mmap filename, width, height
          length = width * height * 4
          mmap_prot = Internal::PROT_READ |
                      Internal::PROT_WRITE
          mmap_flags = Internal::MAP_SHARED
          pagesize = Internal.getpagesize
          mmap_length = ((length / pagesize) + 1) * pagesize

          fcntl_flags = Fcntl::O_RDWR | Fcntl::O_CREAT
          fd = Internal.shm_open filename, fcntl_flags, 0o644
          io = IO.new(fd)
          class << io; self; end.instance_eval do
            define_method("path") { filename }
          end
          Internal.ftruncate fd, mmap_length if io.stat.size != mmap_length
          data = Internal.mmap(nil, mmap_length,
                               mmap_prot, mmap_flags,
                               fd, 0)
          [ data, io ]
        end
      end
    end
  end
end
