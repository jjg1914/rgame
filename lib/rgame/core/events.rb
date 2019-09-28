# frozen_string_literal: true

module RGame
  module Core
    module Events
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

        def initialize text
          @text = text
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
