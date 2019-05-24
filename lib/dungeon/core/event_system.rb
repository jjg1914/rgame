require "thread"
require "dungeon/core/sdl"

module Dungeon
  module Core
    class EventSystem
      class QuitEvent
      end

      class IntervalEvent
        attr_reader :now
        alias_method :t, :now
        attr_reader :dt

        def initialize now, dt
          @now = now
          @dt = dt
        end
      end

      class ModifierState
        attr_accessor :left_ctrl
        attr_accessor :left_shift
        attr_accessor :left_alt
        attr_accessor :left_super
        attr_accessor :right_ctrl
        attr_accessor :right_shift
        attr_accessor :right_alt
        attr_accessor :right_super

        def initialize
          @left_ctrl = false
          @left_shift = false
          @left_alt = false
          @left_super = false
          @right_ctrl = false
          @right_shift = false
          @right_alt = false
          @right_super = false
        end

        def ctrl
          self.left_ctrl or self.right_ctrl
        end

        def shift
          self.left_shift or self.right_shift
        end

        def alt
          self.left_alt or self.right_alt
        end

        def super
          self.left_super or self.right_super
        end
      end

      class KeyEvent
        attr_reader :key_code
        attr_reader :scan_code
        attr_reader :modifiers

        SCAN_CODE_STRINGS = {
          :SDL_SCANCODE_RETURN => "return",
          :SDL_SCANCODE_ESCAPE=> "escape",
          :SDL_SCANCODE_BACKSPACE => "backspace",
          :SDL_SCANCODE_TAB => "tab",
          :SDL_SCANCODE_SPACE => "space",
          :SDL_SCANCODE_F1 => "f1",
          :SDL_SCANCODE_F2 => "f2",
          :SDL_SCANCODE_F3 => "f3",
          :SDL_SCANCODE_F4 => "f4",
          :SDL_SCANCODE_F5 => "f5",
          :SDL_SCANCODE_F6 => "f6",
          :SDL_SCANCODE_F7 => "f7",
          :SDL_SCANCODE_F8 => "f8",
          :SDL_SCANCODE_F9 => "f9",
          :SDL_SCANCODE_F10 => "f10",
          :SDL_SCANCODE_F11 => "f11",
          :SDL_SCANCODE_F12 => "f12",
          :SDL_SCANCODE_PAGEUP => "page_up",
          :SDL_SCANCODE_DELETE => "delete",
          :SDL_SCANCODE_PAGEDOWN => "page_down",
          :SDL_SCANCODE_RIGHT => "right",
          :SDL_SCANCODE_LEFT => "left",
          :SDL_SCANCODE_DOWN => "down",
          :SDL_SCANCODE_UP => "up",
          :SDL_SCANCODE_LCTRL => "left_ctrl",
          :SDL_SCANCODE_LSHIFT => "left_shift",
          :SDL_SCANCODE_LALT => "left_alt", # alt, option
          :SDL_SCANCODE_LGUI => "left_super", # windows, command (apple), meta
          :SDL_SCANCODE_RCTRL => "right_ctrl",
          :SDL_SCANCODE_RSHIFT => "right_shift",
          :SDL_SCANCODE_RALT => "right_alt", # alt gr, option
          :SDL_SCANCODE_RGUI => "right_super", # windows, command (apple), meta
          :SDL_SCANCODE_ENTER => "enter",
        }

        def initialize key_code, scan_code, modifiers
          @key_code = key_code
          @scan_code = scan_code
          @modifiers = modifiers
        end

        def key
          if SCAN_CODE_STRINGS.has_key?(scan_code)
            SCAN_CODE_STRINGS[scan_code]
          elsif key_code < 256
            key_code.chr
          else
            key_code
          end
        end
      end

      class KeydownEvent < KeyEvent; end
      class KeyrepeatEvent < KeyEvent; end
      class KeyupEvent < KeyEvent; end

      class MouseMoveEvent
        attr_reader :x
        attr_reader :y
        attr_reader :modifiers

        def initialize x, y, modifiers
          @x = x
          @y = y
          @modifiers = modifiers
        end
      end

      class MouseButtonEvent
        attr_reader :x
        attr_reader :y
        attr_reader :modifiers

        def initialize x, y, button, modifiers
          @x = x
          @y = y
          @button = button
          @modifiers = modifiers
        end

        def button
          case @button
          when SDL2::SDL_BUTTON_LEFT
            "left"
          when SDL2::SDL_BUTTON_MIDDLE
            "middle"
          when SDL2::SDL_BUTTON_RIGHT
            "right"
          when SDL2::SDL_BUTTON_X1
            "x1"
          when SDL2::SDL_BUTTON_X2
            "x2"
          end
        end
      end

      class MouseButtondownEvent < MouseButtonEvent; end
      class MouseButtonupEvent < MouseButtonEvent; end

      include Enumerable

      attr_reader :now

      def self.open *args
        if block_given?
          video = self.open(*args)
          yield video
          video.close
        else
          self.new.tap { |o| o.open(*args) }
        end
      end

      def open
        @event = SDL2::SDL_Event.new
        @now = 0
        @internal = []
        @mutex = Mutex.new
        @modifiers = ModifierState.new
      end

      def each fps = nil, &block
        if block_given?
          self.each(fps).each(&block)
        else
          waitticks = fps.nil? ? 0 : (1000 / fps).to_i

          Enumerator.new do |yielder|
            begin
              catch :done do
                loop do
                  @now, diff = _ticks_since @now

                  _pump_events(yielder)
                  yielder << IntervalEvent.new(@now, diff)

                  diff2 = _ticks_since(@now)[1]
                  SDL2.SDL_Delay(waitticks - diff2) if diff2 < waitticks
                end
              end
            rescue Interrupt
              yielder << QuitEvent.new
            end
          end
        end
      end

      def close
      end

      def << event
        @mutex.synchronize { @internal << event }
      end

      private

      def _ticks_since last
        now = SDL2.SDL_GetTicks
        now >= last ? [ now, now - last ] : [ now, now + (0xFFFFFFFF - last) ]
      end

      def _pump_events yielder
        flag = false

        unless @internal.empty?
          @mutex.synchronize do
            @internal.each { |e| yielder << e }
            @internal.clear
          end
        end

        while SDL2.SDL_PollEvent(@event) != 0
          case @event[:type]
          when SDL2::SDL_KEYUP
            case @event[:key][:keysym][:scancode]
            when :SDL_SCANCODE_LCTRL
              @modifiers.left_ctrl = false
            when :SDL_SCANCODE_LSHIFT
              @modifiers.left_shift = false 
            when :SDL_SCANCODE_LALT
              @modifiers.left_alt = false 
            when :SDL_SCANCODE_LGUI
              @modifiers.left_super = false
            when :SDL_SCANCODE_RCTRL
              @modifiers.right_ctrl = false
            when :SDL_SCANCODE_RSHIFT
              @modifiers.right_shift = false 
            when :SDL_SCANCODE_RALT
              @modifiers.right_alt = false 
            when :SDL_SCANCODE_RGUI
              @modifiers.right_super = false
            end

            yielder << KeyupEvent.new(@event[:key][:keysym][:sym],
                                      @event[:key][:keysym][:scancode],
                                      @modifiers)
          when SDL2::SDL_KEYDOWN
            if @event[:key][:repeat] == 0
              case @event[:key][:keysym][:scancode]
              when :SDL_SCANCODE_LCTRL
                @modifiers.left_ctrl = true
              when :SDL_SCANCODE_LSHIFT
                @modifiers.left_shift = true 
              when :SDL_SCANCODE_LALT
                @modifiers.left_alt = true 
              when :SDL_SCANCODE_LGUI
                @modifiers.left_super = true
              when :SDL_SCANCODE_RCTRL
                @modifiers.right_ctrl = true
              when :SDL_SCANCODE_RSHIFT
                @modifiers.right_shift = true 
              when :SDL_SCANCODE_RALT
                @modifiers.right_alt = true 
              when :SDL_SCANCODE_RGUI
                @modifiers.right_super = true
              end

              yielder << KeydownEvent.new(@event[:key][:keysym][:sym],
                                          @event[:key][:keysym][:scancode],
                                          @modifiers)
            else
              yielder << KeyrepeatEvent.new(@event[:key][:keysym][:sym],
                                            @event[:key][:keysym][:scancode],
                                            @modifiers)
            end
          when SDL2::SDL_MOUSEMOTION
            yielder << MouseMoveEvent.new(@event[:motion][:x],
                                          @event[:motion][:y],
                                          @modifiers)
          when SDL2::SDL_MOUSEBUTTONDOWN
            yielder << MouseButtondownEvent.new(@event[:button][:x],
                                                @event[:button][:y],
                                                @event[:button][:button],
                                                @modifiers)
          when SDL2::SDL_MOUSEBUTTONUP
            yielder << MouseButtonupEvent.new(@event[:button][:x],
                                              @event[:button][:y],
                                              @event[:button][:button],
                                              @modifiers)
          when SDL2::SDL_WINDOWEVENT
            if @event[:window][:event] == :SDL_WINDOWEVENT_CLOSE
              flag = true
              yielder << QuitEvent.new
            end
          when SDL2::SDL_QUIT
            flag = true
            yielder << QuitEvent.new
          end
        end

        throw :done if flag
      end
    end
  end
end
