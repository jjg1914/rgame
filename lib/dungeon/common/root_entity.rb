# frozen_string_literal: true

require "dungeon/core/events"
require "dungeon/core/sdl_context"
require "dungeon/common/collection_entity"

module Dungeon
  module Common
    class RootEntity < CollectionEntity
      on :event_loop do
        raise "context not opened" if self.context.nil?

        self.emit :start

        self.context.each(60) { |e| event_loop_step(e) }

        self.emit :end
      end

      after :interval do
        self.emit :draw
        self.ctx.present
      end

      def self.run!
        self.new.tap { |o| o.emit :event_loop }
      end

      def open_context title, width, height
        @context = Dungeon::Core::SDLContext.open(title, width, height)
      end

      private

      # rubocop:disable Metrics/CyclomaticComplexity
      def event_loop_step event
        case event
        when Dungeon::Core::Events::KeyupEvent
          event_loop_keyup event
        when Dungeon::Core::Events::KeydownEvent
          event_loop_keydown event
        when Dungeon::Core::Events::KeyrepeatEvent
          event_loop_keyrepeat event
        when Dungeon::Core::Events::TextInputEvent
          event_loop_textinput event
        when Dungeon::Core::Events::IntervalEvent
          event_loop_interval event
        when Dungeon::Core::Events::MouseMoveEvent
          event_loop_mousemove event
        when Dungeon::Core::Events::MouseButtonupEvent
          event_loop_mouseup event
        when Dungeon::Core::Events::MouseButtondownEvent
          event_loop_mousedown event
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def event_loop_keyup event
        self.emit :keyup, event.key, event.modifiers
      end

      def event_loop_keydown event
        self.emit :keydown, event.key, event.modifiers
      end

      def event_loop_keyrepeat event
        self.emit :keyrepeat, event.key, event.modifiers
      end

      def event_loop_textinput event
        self.emit :textinput, event.text
      end

      def event_loop_interval event
        self.emit :interval, event.dt
      end

      def event_loop_mousemove event
        self.emit :mousemove,
                  (event.x / self.context.scale[0]).to_i,
                  (event.y / self.context.scale[1]).to_i,
                  event.modifiers
      end

      def event_loop_mouseup event
        self.emit :mouseup,
                  (event.x / self.context.scale[0]).to_i,
                  (event.y / self.context.scale[1]).to_i,
                  event.button, event.modifiers
      end

      def event_loop_mousedown event
        self.emit :mousedown,
                  (event.x / self.context.scale[0]).to_i,
                  (event.y / self.context.scale[1]).to_i,
                  event.button, event.modifiers
      end
    end
  end
end
