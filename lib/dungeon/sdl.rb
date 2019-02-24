require "ffi"

module Dungeon
  module SDL2
    extend FFI::Library
    ffi_lib "SDL2"

    attach_function :SDL_Init, [ :uint32 ], :int
    attach_function :SDL_Quit, [], :void
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
    attach_function :SDL_RenderClear, [ :pointer ], :int
    attach_function :SDL_RenderDrawRect, [ :pointer, :pointer ], :int
    attach_function :SDL_RenderFillRect, [ :pointer, :pointer ], :int

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
      :SDL_SCANCODE_RIGHT, 79,
      :SDL_SCANCODE_LEFT, 80,
      :SDL_SCANCODE_DOWN, 81,
      :SDL_SCANCODE_UP, 82,
      :SDL_NUM_SCANCODES, 512,
    ]

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

    class SDL_Event < FFI::Union
      layout :type, :uint32,
             :window, SDL_WindowEvent,
             :key, SDL_KeyboardEvent
    end

    class SDL_Rect < FFI::Struct
      layout :x, :int,
             :y, :int,
             :w, :int,
             :h, :int
    end

    SDL_INIT_VIDEO = 0x10
    SDL_WINDOW_SHOWN = 0x4
    SDL_WINDOW_OPENGL = 0x2
    SDL_RENDERER_ACCELERATED = 0x2

    SDL_QUIT = 0x100
    SDL_WINDOWEVENT = 0x200
    SDL_KEYDOWN = 0x300
    SDL_KEYUP = 0x301
  end
end