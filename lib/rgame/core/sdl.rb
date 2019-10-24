# frozen_string_literal: true

require "ffi"

module RGame
  module Core
    EXT_PATH = File.expand_path("../../../ext", File.dirname(__FILE__))

    module Internal
      unless (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
        raise "not supported"
      end

      PROT_NONE = 0x0
      PROT_READ = 0x1
      PROT_WRITE = 0x2
      PROT_EXEC = 0x4

      MAP_SHARED = 0x1
      MAP_PRIVATE = 0x2

      class << self
        def getpagesize *args
          Internal::LibC.getpagesize(*args)
        end

        def ftruncate *args
          Internal::LibC.ftruncate(*args)
        end

        def mmap *args
          Internal::LibC.mmap(*args)
        end

        def munmap *args
          Internal::LibC.munmap(*args)
        end

        if (/darwin/ =~ RUBY_PLATFORM).nil?
          def shm_open *args
            Internal::LibRT.shm_open(*args)
          end

          def shm_unlink *args
            Internal::LibRT.shm_unlink(*args)
          end
        else
          def shm_open *args
            Internal::LibC.shm_open(*args)
          end

          def shm_unlink *args
            Internal::LibC.shm_unlink(*args)
          end
        end
      end

      module LibC
        extend FFI::Library
        ffi_lib FFI::Library::LIBC

        attach_function :getpagesize, %i[], :int
        attach_function :ftruncate, %i[int int64], :int

        unless (/darwin/ =~ RUBY_PLATFORM).nil?
          attach_function :shm_open, %i[string int uint32], :int
          attach_function :shm_unlink, %i[string], :int
        end

        attach_function :mmap, %i[pointer
                                  ulong
                                  int
                                  int
                                  int
                                  uint], :pointer
        attach_function :munmap, %i[pointer ulong], :pointer
      end

      if (/darwin/ =~ RUBY_PLATFORM).nil?
        module LibRT
          extend FFI::Library
          ffi_lib "rt"

          attach_function :shm_open, %i[string int uint32], :int
          attach_function :shm_unlink, %i[string], :int
        end
      end
    end

    # rubocop:disable Metrics/ModuleLength
    module SDL2
      extend FFI::Library
      ffi_lib "SDL2"

      enum :SDLWindowEventID, %i[
        SDL_WINDOWEVENT_NONE
        SDL_WINDOWEVENT_SHOWN
        SDL_WINDOWEVENT_HIDDEN
        SDL_WINDOWEVENT_EXPOSED
        SDL_WINDOWEVENT_MOVED
        SDL_WINDOWEVENT_RESIZED
        SDL_WINDOWEVENT_SIZE_CHANGED
        SDL_WINDOWEVENT_MINIMIZED
        SDL_WINDOWEVENT_MAXIMIZED
        SDL_WINDOWEVENT_RESTORED
        SDL_WINDOWEVENT_ENTER
        SDL_WINDOWEVENT_LEAVE
        SDL_WINDOWEVENT_FOCUS_GAINED
        SDL_WINDOWEVENT_FOCUS_LOST
        SDL_WINDOWEVENT_CLOSE
        SDL_WINDOWEVENT_TAKE_FOCUS
        SDL_WINDOWEVENT_HIT_TEST
      ]

      enum :SDL_Scancode, [
        :SDL_SCANCODE_UNKNOWN, 0,
        :SDL_SCANCODE_RETURN, 40,
        :SDL_SCANCODE_ESCAPE, 41,
        :SDL_SCANCODE_BACKSPACE, 42,
        :SDL_SCANCODE_TAB, 43,
        :SDL_SCANCODE_SPACE, 44,
        :SDL_SCANCODE_F1, 58,
        :SDL_SCANCODE_F2, 59,
        :SDL_SCANCODE_F3, 60,
        :SDL_SCANCODE_F4, 61,
        :SDL_SCANCODE_F5, 62,
        :SDL_SCANCODE_F6, 63,
        :SDL_SCANCODE_F7, 64,
        :SDL_SCANCODE_F8, 65,
        :SDL_SCANCODE_F9, 66,
        :SDL_SCANCODE_F10, 67,
        :SDL_SCANCODE_F11, 68,
        :SDL_SCANCODE_F12, 69,
        :SDL_SCANCODE_INSERT, 73,
        :SDL_SCANCODE_HOME, 74,
        :SDL_SCANCODE_PAGEUP, 75,
        :SDL_SCANCODE_DELETE, 76,
        :SDL_SCANCODE_END, 77,
        :SDL_SCANCODE_PAGEDOWN, 78,
        :SDL_SCANCODE_RIGHT, 79,
        :SDL_SCANCODE_LEFT, 80,
        :SDL_SCANCODE_DOWN, 81,
        :SDL_SCANCODE_UP, 82,
        :SDL_SCANCODE_ENTER, 88,
        :SDL_SCANCODE_LCTRL, 224,
        :SDL_SCANCODE_LSHIFT, 225,
        :SDL_SCANCODE_LALT, 226, # alt, option
        :SDL_SCANCODE_LGUI, 227, # windows, command (apple), meta
        :SDL_SCANCODE_RCTRL, 228,
        :SDL_SCANCODE_RSHIFT, 229,
        :SDL_SCANCODE_RALT, 230, # alt gr, option
        :SDL_SCANCODE_RGUI, 231, # windows, command (apple), meta
        :SDL_NUM_SCANCODES, 512,
      ]

      SDL_INIT_AUDIO = 0x10
      SDL_INIT_VIDEO = 0x20
      SDL_WINDOW_SHOWN = 0x4
      SDL_WINDOW_OPENGL = 0x2
      SDL_RENDERER_ACCELERATED = 0x2
      SDL_RENDERER_PRESENTVSYNC = 0x4

      SDL_QUIT = 0x100
      SDL_WINDOWEVENT = 0x200
      SDL_KEYDOWN = 0x300
      SDL_KEYUP = 0x301
      SDL_TEXTEDITING = 0x302
      SDL_TEXTINPUT = 0x303
      SDL_MOUSEMOTION = 0x400
      SDL_MOUSEBUTTONDOWN = 0x401
      SDL_MOUSEBUTTONUP = 0x402
      SDL_MOUSEWHEEL = 0x403

      SDL_HINT_RENDER_SCALE_QUALITY = "SDL_RENDER_SCALE_QUALITY"
      SDL_HINT_RENDER_VSYNC = "SDL_RENDER_VSYNC"

      SDL_TEXTUREACCESS_STATIC = 0x0
      SDL_TEXTUREACCESS_STREAMING = 0x1
      SDL_TEXTUREACCESS_TARGET = 0x2

      SDL_BLENDMODE_NONE = 0x0
      SDL_BLENDMODE_BLEND = 0x1
      SDL_BLENDMODE_ADD = 0x2
      SDL_BLENDMODE_MOD = 0x4
      SDL_BLENDMODE_INVALID = 0x7FFFFFFF

      SDL_BUTTON_LEFT = 0x1
      SDL_BUTTON_MIDDLE = 0x2
      SDL_BUTTON_RIGHT = 0x3
      SDL_BUTTON_X1 = 0x4
      SDL_BUTTON_X2 = 0x5

      class SDLKeysym < FFI::Struct
        layout :scancode, :SDL_Scancode,
               :sym, :int32,
               :mod, :uint16,
               :unused, :uint32
      end

      class SDLWindowEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :event, :SDLWindowEventID,
               :padding1, :uint8,
               :padding2, :uint8,
               :padding3, :uint8,
               :data1, :int32,
               :data2, :int32
      end

      class SDLKeyboardEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :state, :uint8,
               :repeat, :uint8,
               :padding2, :uint8,
               :padding3, :uint8,
               :keysym, SDLKeysym
      end

      class SDLMouseMotionEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :which, :uint32,
               :state, :uint32,
               :x, :int32,
               :y, :int32,
               :xrel, :int32,
               :yrel, :int32
      end

      class SDLMouseButtonEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :which, :uint32,
               :button, :uint8,
               :state, :uint8,
               :clicks, :uint8,
               :padding1, :uint8,
               :x, :int32,
               :y, :int32
      end

      class SDLMouseWheelEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :which, :uint32,
               :x, :int32,
               :y, :int32,
               :direction, :uint32
      end

      class SDLTextInputEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :text, [ :char, 32 ]
      end

      class SDLEvent < FFI::Union
        layout :type, :uint32,
               :window, SDLWindowEvent,
               :key, SDLKeyboardEvent,
               :text, SDLTextInputEvent,
               :motion, SDLMouseMotionEvent,
               :button, SDLMouseButtonEvent,
               :wheel, SDLMouseWheelEvent
      end

      class SDLRect < FFI::Struct
        layout :x, :int,
               :y, :int,
               :w, :int,
               :h, :int
      end

      class SDLColor < FFI::Struct
        layout :r, :uint8,
               :g, :uint8,
               :b, :uint8,
               :a, :uint8

        def assign red, green, blue, alpha
          self[:r] = red
          self[:g] = green
          self[:b] = blue
          self[:a] = alpha
        end

        def assign_rgb_a rgb, alpha
          red, green, blue = _to_rgb(rgb)
          self.assign red, green, blue, alpha
        end

        private

        def _to_rgb rgb
          [ _red_value(rgb), _green_value(rgb), _blue_value(rgb) ]
        end

        def _red_value rgba
          # TODO ENDIAN
          (rgba & 0x00FF0000) >> 16
        end

        def _green_value rgba
          # TODO ENDIAN
          (rgba & 0x0000FF00) >> 8
        end

        def _blue_value rgba
          # TODO ENDIAN
          (rgba & 0x000000FF)
        end
      end

      class SDLSurface < FFI::Struct
        layout :flags, :uint32,
               :format, :pointer,
               :w, :int,
               :h, :int,
               :pitch, :int,
               :pixels, :pointer,
               :userdata, :pointer,
               :locked, :int,
               :lock_data, :pointer,
               :clip_rect, SDLRect,
               :map, :pointer,
               :refcount, :int
      end

      attach_function :SDL_Init, %i[uint32], :int
      attach_function :SDL_Quit, [], :void
      attach_function :SDL_GetError, [], :string
      attach_function :SDL_Delay, %i[int], :void
      attach_function :SDL_GetTicks, [], :uint32
      attach_function :SDL_CreateWindow, %i[string
                                            int int int int
                                            uint32], :pointer
      attach_function :SDL_DestroyWindow, %i[pointer], :void
      attach_function :SDL_CreateRenderer, %i[pointer int uint32], :pointer
      attach_function :SDL_CreateSoftwareRenderer, %i[pointer], :pointer
      attach_function :SDL_DestroyRenderer, %i[pointer], :void
      attach_function :SDL_PollEvent, %i[pointer], :int
      attach_function :SDL_PushEvent, %i[pointer], :int
      attach_function :SDL_RenderPresent, %i[pointer], :void
      attach_function :SDL_SetRenderDrawColor, %i[pointer int int int int], :int
      attach_function :SDL_GetRenderDrawColor, %i[
        pointer
        pointer
        pointer
        pointer
        pointer
      ], :int
      attach_function :SDL_RenderSetScale, %i[pointer float float], :int
      attach_function :SDL_RenderGetScale, %i[pointer pointer pointer], :void
      attach_function :SDL_SetRenderTarget, %i[pointer pointer], :int
      attach_function :SDL_GetRenderTarget, %i[pointer], :pointer
      attach_function :SDL_GetHint, %i[string], :string
      attach_function :SDL_SetHint, %i[string string], :int
      attach_function :SDL_RenderClear, %i[pointer], :int
      attach_function :SDL_RenderDrawRect, %i[pointer pointer], :int
      attach_function :SDL_RenderFillRect, %i[pointer pointer], :int
      attach_function :SDL_RenderCopy, %i[pointer pointer pointer pointer], :int
      attach_function :SDL_CreateTextureFromSurface, %i[pointer
                                                        pointer], :pointer
      attach_function :SDL_CreateTexture, %i[pointer uint32 int
                                             int int], :pointer
      attach_function :SDL_DestroyTexture, [ :pointer ], :void
      attach_function :SDL_QueryTexture, %i[pointer pointer pointer
                                            pointer pointer], :int
      attach_function :SDL_CreateRGBSurface, %i[uint32 int int int
                                                uint32 uint32 uint32
                                                uint32], SDLSurface.ptr
      attach_function :SDL_CreateRGBSurfaceFrom, %i[pointer
                                                    int
                                                    int
                                                    int
                                                    int
                                                    uint32
                                                    uint32
                                                    uint32
                                                    uint32], SDLSurface.ptr
      attach_function :SDL_CreateRGBSurfaceWithFormat,
                      %i[uint32 int int int uint32],
                      SDLSurface.ptr
      attach_function :SDL_FreeSurface, %i[pointer], :void
      attach_function :SDL_SetTextureBlendMode, %i[pointer int], :int
      attach_function :SDL_GetTextureBlendMode, %i[pointer pointer], :int
      attach_function :SDL_GetWindowPixelFormat, %i[pointer], :uint32
      attach_function :SDL_MasksToPixelFormatEnum, %i[int
                                                      uint32
                                                      uint32
                                                      uint32
                                                      uint32], :uint32
      attach_function :SDL_StartTextInput, [], :void
      attach_function :SDL_StopTextInput, [], :void
      attach_function :SDL_SetTextInputRect, [ :pointer ], :void
      attach_function :SDL_IsTextInputActive, [], :bool
      attach_function :SDL_GetClipboardText, [], :string
      attach_function :SDL_SetClipboardText, [ :string ], :int
      attach_function :SDL_HasClipboardText, [], :bool
      attach_function :SDL_RenderSetClipRect, %i[pointer pointer], :int

      attach_function :SDL_RWFromFile, %i[string string], :pointer
      attach_function :SDL_SaveBMP_RW, %i[pointer pointer int], :int

      SDL_PIXELFORMAT_BGRX8888 = self.SDL_MasksToPixelFormatEnum 32,
                                                                 0x0,
                                                                 0xFF0000,
                                                                 0xFF00,
                                                                 0xFF
      SDL_PIXELFORMAT_ARGB8888 = self.SDL_MasksToPixelFormatEnum 32,
                                                                 0xFF000000,
                                                                 0xFF0000,
                                                                 0xFF00,
                                                                 0xFF
      SDL_PIXELFORMAT_RGBA8888 = self.SDL_MasksToPixelFormatEnum 32,
                                                                 0xFF0000,
                                                                 0xFF00,
                                                                 0xFF,
                                                                 0xFF000000
      SDL_PIXELFORMAT_ABGR8888 = self.SDL_MasksToPixelFormatEnum 32,
                                                                 0xFF000000,
                                                                 0xFF,
                                                                 0xFF00,
                                                                 0xFF0000
      SDL_PIXELFORMAT_BGRA8888 = self.SDL_MasksToPixelFormatEnum 32,
                                                                 0xFF00,
                                                                 0xFF0000,
                                                                 0xFF000000,
                                                                 0xFF
    end

    module SDL2Image
      extend FFI::Library
      ffi_lib "SDL2_image"

      attach_function :IMG_Load, [ :string ], :pointer
      attach_function :IMG_Init, [ :uint32 ], :int
      attach_function :IMG_Quit, [], :void

      IMG_INIT_PNG = 0x2
    end

    module SDL2Mixer
      extend FFI::Library
      ffi_lib "SDL2_mixer"

      AUDIO_S16LSB = 0x8010
      AUDIO_S16MSB = 0x9010

      # NOTE Little endian only!
      MIX_DEFAULT_FORMAT = AUDIO_S16LSB

      callback :channel_finished, %i[int], :void

      attach_function :Mix_Init, %i[int], :int
      attach_function :Mix_Quit, %i[], :void
      attach_function :Mix_OpenAudio, %i[int uint16 int int], :int
      attach_function :Mix_CloseAudio, %i[], :void

      attach_function :Mix_LoadWAV_RW, %i[pointer int], :pointer
      attach_function :Mix_FreeChunk, %i[pointer], :void

      attach_function :Mix_AllocateChannels, %i[int], :int

      attach_function :Mix_PlayChannelTimed, %i[int pointer int int], :int
      attach_function :Mix_Volume, %i[int int], :int
      attach_function :Mix_Pause, %i[int], :void
      attach_function :Mix_Resume, %i[int], :void
      attach_function :Mix_HaltChannel, %i[int], :int
      attach_function :Mix_Paused, %i[int], :int
      attach_function :Mix_ChannelFinished, %i[channel_finished], :void
    end

    module SDL2TTF
      extend FFI::Library
      ffi_lib "SDL2_ttf"

      TTF_STYLE_NORMAL = 0x0
      TTF_STYLE_BOLD = 0x1
      TTF_STYLE_ITALIC = 0x2
      TTF_STYLE_UNDERLINE = 0x4
      TTF_STYLE_STRIKETHROUGH = 0x8

      attach_function :TTF_Init, [], :int
      attach_function :TTF_Quit, [], :void
      attach_function :TTF_OpenFont, %i[string int], :pointer
      attach_function :TTF_RenderText_Solid, [
        :pointer,
        :string,
        SDL2::SDLColor.by_value,
      ], :pointer
      attach_function :TTF_SizeText, %i[
        pointer
        string
        pointer
        pointer
      ], :int
    end

    module SDLFontCache
      extend FFI::Library

      if not (/darwin/ =~ RUBY_PLATFORM).nil?
        ffi_lib File.expand_path("SDL_FontCache.bundle", EXT_PATH)
      else
        ffi_lib File.expand_path("SDL_FontCache.so", EXT_PATH)
      end

      attach_function :FC_CreateFont, [], :pointer
      attach_function :FC_LoadFont, [
        :pointer,
        :pointer,
        :string,
        :uint32,
        SDL2::SDLColor.by_value,
        :int,
      ], :uint8
      attach_function :FC_Draw, %i[pointer
                                   pointer
                                   float
                                   float
                                   string], SDL2::SDLRect.by_value
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
