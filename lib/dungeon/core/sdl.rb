require "ffi"

module Dungeon
  module Core
    module SDL2
      extend FFI::Library
      ffi_lib "SDL2"

      enum :SDL_WindowEventID, [
        :SDL_WINDOWEVENT_NONE,
        :SDL_WINDOWEVENT_SHOWN,
        :SDL_WINDOWEVENT_HIDDEN,
        :SDL_WINDOWEVENT_EXPOSED,
        :SDL_WINDOWEVENT_MOVED,
        :SDL_WINDOWEVENT_RESIZED,
        :SDL_WINDOWEVENT_SIZE_CHANGED,
        :SDL_WINDOWEVENT_MINIMIZED,
        :SDL_WINDOWEVENT_MAXIMIZED,
        :SDL_WINDOWEVENT_RESTORED,
        :SDL_WINDOWEVENT_ENTER,
        :SDL_WINDOWEVENT_LEAVE,
        :SDL_WINDOWEVENT_FOCUS_GAINED,
        :SDL_WINDOWEVENT_FOCUS_LOST,
        :SDL_WINDOWEVENT_CLOSE,
        :SDL_WINDOWEVENT_TAKE_FOCUS,
        :SDL_WINDOWEVENT_HIT_TEST ,
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
        :SDL_SCANCODE_PAGEUP, 75,
        :SDL_SCANCODE_DELETE, 76,
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
      attach_function :SDL_Init, [ :uint32 ], :int
      attach_function :SDL_Quit, [], :void
      attach_function :SDL_GetError, [], :string
      attach_function :SDL_Delay, [ :int ], :void
      attach_function :SDL_GetTicks, [], :uint32
      attach_function :SDL_CreateWindow, [ :string,
                                           :int, :int, :int, :int,
                                           :uint32 ], :pointer
      attach_function :SDL_DestroyWindow, [ :pointer ], :void
      attach_function :SDL_CreateRenderer, [ :pointer, :int, :uint32 ], :pointer
      attach_function :SDL_DestroyRenderer, [ :pointer ], :void
      attach_function :SDL_PollEvent, [ :pointer ], :int
      attach_function :SDL_RenderPresent, [ :pointer ], :void
      attach_function :SDL_SetRenderDrawColor, [ :pointer, :int, :int, :int, :int ], :int
      attach_function :SDL_RenderSetScale, [ :pointer, :float, :float ], :int
      attach_function :SDL_SetRenderTarget, [ :pointer, :pointer ], :int
      attach_function :SDL_GetRenderTarget, [ :pointer ], :pointer
      attach_function :SDL_GetHint, [ :string ], :string
      attach_function :SDL_SetHint, [ :string, :string ], :int
      attach_function :SDL_RenderClear, [ :pointer ], :int
      attach_function :SDL_RenderDrawRect, [ :pointer, :pointer ], :int
      attach_function :SDL_RenderFillRect, [ :pointer, :pointer ], :int
      attach_function :SDL_RenderCopy, [ :pointer, :pointer, :pointer, :pointer ], :int
      attach_function :SDL_CreateTextureFromSurface, [ :pointer, :pointer ], :pointer
      attach_function :SDL_CreateTexture, [ :pointer, :uint32, :int, :int, :int ], :pointer
      attach_function :SDL_DestroyTexture, [ :pointer ], :void
      attach_function :SDL_QueryTexture, [ :pointer, :pointer, :pointer, :pointer, :pointer ], :int
      attach_function :SDL_CreateRGBSurface, [ :uint32, :int, :int, :int,
                                               :uint32, :uint32, :uint32,
                                               :uint32 ], :pointer
      attach_function :SDL_FreeSurface, [ :pointer ], :void
      attach_function :SDL_SetTextureBlendMode, [ :pointer, :int ], :int
      attach_function :SDL_GetTextureBlendMode, [ :pointer, :pointer ], :int
      attach_function :SDL_GetWindowPixelFormat, [ :pointer ], :uint32

      class SDL_Keysym < FFI::Struct
        layout :scancode, :SDL_Scancode,
               :sym, :int32,
               :mod, :uint16,
               :unused, :uint32
      end

      class SDL_WindowEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :event, :SDL_WindowEventID,
               :padding1, :uint8,
               :padding2, :uint8,
               :padding3, :uint8,
               :data1, :int32,
               :data2, :int32
      end

      class SDL_KeyboardEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :state, :uint8,
               :repeat, :uint8,
               :padding2, :uint8,
               :padding3, :uint8,
               :keysym, SDL_Keysym
      end

      class SDL_MouseMotionEvent < FFI::Struct
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

      class SDL_MouseButtonEvent < FFI::Struct
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

      class SDL_MouseWheelEvent < FFI::Struct
        layout :type, :uint32,
               :timestamp, :uint32,
               :windowID, :uint32,
               :which, :uint32,
               :x, :int32,
               :y, :int32,
               :direction, :uint32
      end

      class SDL_Event < FFI::Union
        layout :type, :uint32,
               :window, SDL_WindowEvent,
               :key, SDL_KeyboardEvent,
               :motion, SDL_MouseMotionEvent,
               :button, SDL_MouseButtonEvent,
               :wheel, SDL_MouseWheelEvent
      end

      class SDL_Rect < FFI::Struct
        layout :x, :int,
               :y, :int,
               :w, :int,
               :h, :int
      end

      class SDL_Color < FFI::Struct
        layout :r, :uint8,
               :g, :uint8,
               :b, :uint8,
               :a, :uint8
      end

      SDL_INIT_VIDEO = 0x10
      SDL_WINDOW_SHOWN = 0x4
      SDL_WINDOW_OPENGL = 0x2
      SDL_RENDERER_ACCELERATED = 0x2
      SDL_RENDERER_PRESENTVSYNC = 0x4

      SDL_QUIT = 0x100
      SDL_WINDOWEVENT = 0x200
      SDL_KEYDOWN = 0x300
      SDL_KEYUP = 0x301
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
      SDL_BUTTON_X1= 0x4
      SDL_BUTTON_X2= 0x5
    end

    module SDL2Image
      extend FFI::Library
      ffi_lib "SDL2_image"

      attach_function :IMG_Load, [ :string ], :pointer
      attach_function :IMG_Init, [ :uint32 ], :int
      attach_function :IMG_Quit, [], :void

      IMG_INIT_PNG = 0x2
    end

    module SDL2TTF
      extend FFI::Library
      ffi_lib "SDL2_ttf"

      attach_function :TTF_Init, [], :int
      attach_function :TTF_Quit, [], :void
      attach_function :TTF_OpenFont, [ :string, :int ], :pointer
      attach_function :TTF_RenderText_Solid, [
        :pointer,
        :string,
        SDL2::SDL_Color.by_value,
      ], :pointer
      attach_function :TTF_SizeText, [
        :pointer,
        :string,
        :pointer,
        :pointer,
      ], :int
    end
  end
end
