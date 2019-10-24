# frozen_string_literal: true

require "rgame/core/sdl"

module RGame
  module Core
    module Events
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

        def == other
          other.is_a?(self.class) and
            self.is_a?(other.class) and
            (%i[
              left_ctrl
              left_shift
              left_alt
              left_super
              right_ctrl
              right_shift
              right_alt
              right_super
            ].all? { |e| self.send(e) == other.send(e) })
        end
      end

      class QuitEvent
        def == other
          other.is_a?(self.class) and self.is_a?(other.class)
        end
      end

      class IntervalEvent
        attr_reader :now
        alias t now
        attr_reader :dt

        def initialize now, dt
          @now = now
          @dt = dt
        end

        def == other
          other.is_a?(self.class) and
            self.is_a?(other.class) and
            self.now == other.now and
            self.dt == other.dt
        end
      end

      class KeyEvent
        attr_reader :key
        attr_reader :modifiers

        SDL_SCAN_CODE_STRINGS = {
          :SDL_SCANCODE_RETURN => "return",
          :SDL_SCANCODE_ESCAPE => "escape",
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
          :SDL_SCANCODE_INSERT => "insert",
          :SDL_SCANCODE_HOME => "home",
          :SDL_SCANCODE_PAGEUP => "page_up",
          :SDL_SCANCODE_DELETE => "delete",
          :SDL_SCANCODE_END => "end",
          :SDL_SCANCODE_PAGEDOWN => "page_down",
          :SDL_SCANCODE_RIGHT => "right",
          :SDL_SCANCODE_LEFT => "left",
          :SDL_SCANCODE_DOWN => "down",
          :SDL_SCANCODE_UP => "up",
          :SDL_SCANCODE_LCTRL => "left_ctrl",
          :SDL_SCANCODE_LSHIFT => "left_shift",
          :SDL_SCANCODE_LALT => "left_alt",
          :SDL_SCANCODE_LGUI => "left_super",
          :SDL_SCANCODE_RCTRL => "right_ctrl",
          :SDL_SCANCODE_RSHIFT => "right_shift",
          :SDL_SCANCODE_RALT => "right_alt", # alt gr, option
          :SDL_SCANCODE_RGUI => "right_super", # windows, command, meta
          :SDL_SCANCODE_ENTER => "enter",
        }.freeze

        def self.sdl_key_for key_code, scan_code
          default = if key_code < 256
            key_code.chr
          else
            scan_code
          end
          SDL_SCAN_CODE_STRINGS.fetch(scan_code, default)
        end

        def self.from_sdl sdl_event, modifiers
          key = self.sdl_key_for(sdl_event[:key][:keysym][:sym],
                                 sdl_event[:key][:keysym][:scancode])
          if sdl_event[:key][:repeat].zero?
            self.new(key, modifiers)
          else
            KeyrepeatEvent.new(key, modifiers)
          end
        end

        def initialize key, modifiers
          @key = key
          @modifiers = modifiers
        end

        def == other
          other.is_a?(self.class) and
            self.is_a?(other.class) and
            self.key == other.key and
            self.modifiers == other.modifiers
        end
      end

      class KeyupEvent < KeyEvent; end
      class KeydownEvent < KeyEvent; end
      class KeyrepeatEvent < KeyEvent; end

      class MouseMoveEvent
        attr_reader :x
        attr_reader :y
        attr_reader :modifiers

        def self.from_sdl sdl_event, modifiers
          self.new(sdl_event[:motion][:x], sdl_event[:motion][:y], modifiers)
        end

        def initialize x, y, modifiers
          @x = x
          @y = y
          @modifiers = modifiers
        end

        def == other
          other.is_a?(self.class) and
            self.is_a?(other.class) and
            self.x == other.x and
            self.y == other.y and
            self.modifiers == other.modifiers
        end
      end

      class MouseButtonEvent
        attr_reader :x
        attr_reader :y
        attr_reader :button
        attr_reader :modifiers

        BUTTON_STRINGS = {
          SDL2::SDL_BUTTON_LEFT => "left",
          SDL2::SDL_BUTTON_MIDDLE => "middle",
          SDL2::SDL_BUTTON_RIGHT => "right",
          SDL2::SDL_BUTTON_X1 => "x1",
          SDL2::SDL_BUTTON_X2 => "x2",
        }.freeze

        def self.sdl_button_for button
          BUTTON_STRINGS.fetch(button, button)
        end

        def self.from_sdl sdl_event, modifiers
          button = self.sdl_button_for sdl_event[:button][:button]
          self.new(sdl_event[:button][:x],
                   sdl_event[:button][:y],
                   button,
                   modifiers)
        end

        def initialize x, y, button, modifiers
          @x = x
          @y = y
          @button = button
          @modifiers = modifiers
        end

        def == other
          other.is_a?(self.class) and
            self.is_a?(other.class) and
            self.x == other.x and
            self.y == other.y and
            self.button == other.button and
            self.modifiers == other.modifiers
        end
      end

      class MouseButtondownEvent < MouseButtonEvent; end
      class MouseButtonupEvent < MouseButtonEvent; end

      class TextInputEvent
        attr_reader :text
        attr_reader :modifiers

        def self.from_sdl sdl_event, modifiers
          text = sdl_event[:text][:text].to_ptr.read_string
          self.new(text, modifiers)
        end

        def initialize text, modifiers
          @text = text
          @modifiers = modifiers
        end

        def == other
          other.is_a?(self.class) and
            self.is_a?(other.class) and
            self.text == other.text
        end
      end
    end
  end
end
