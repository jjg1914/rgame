# frozen_string_literal: true

module Dungeon
  module Core
    module Events
      class QuitEvent
      end

      class IntervalEvent
        attr_reader :now
        alias t now
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
        attr_reader :key
        attr_reader :modifiers

        def initialize key, modifiers
          @key = key
          @modifiers = modifiers
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
        attr_reader :button
        attr_reader :modifiers

        def initialize x, y, button, modifiers
          @x = x
          @y = y
          @button = button
          @modifiers = modifiers
        end
      end

      class MouseButtondownEvent < MouseButtonEvent; end
      class MouseButtonupEvent < MouseButtonEvent; end

      class TextInputEvent
        attr_reader :text

        def initialize text
          @text = text
        end
      end
    end
  end
end
