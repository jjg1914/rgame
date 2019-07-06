require "dungeon/core/events"
require "dungeon/core/sdl_context"
require "dungeon/common/collection_entity"

module Dungeon
  module Common
    class RootEntity < CollectionEntity
      attr_reader :context

      on :event_loop do
        raise "context not opened" if self.context.nil?

        let_vars({
          "ctx" => self.context,
        }) do
          self.emit :start

          self.context.each do |e|
            case e
            when Dungeon::Core::Events::KeyupEvent
              self.emit :keyup, e.key, e.modifiers
            when Dungeon::Core::Events::KeydownEvent
              self.emit :keydown, e.key, e.modifiers
            when Dungeon::Core::Events::KeyrepeatEvent
              self.emit :keyrepeat, e.key, e.modifiers
            when Dungeon::Core::Events::TextInputEvent
              self.emit :textinput, e.text
            when Dungeon::Core::Events::IntervalEvent
              self.emit :interval, e.dt
            when Dungeon::Core::Events::MouseMoveEvent
              scale = self.context.scale
              self.emit :mousemove, (e.x / scale[0]).to_i,
                                    (e.y / scale[1]).to_i,
                                    e.modifiers
            when Dungeon::Core::Events::MouseButtonupEvent
              scale = self.context.scale
              self.emit :mouseup, (e.x / scale[0]).to_i,
                                  (e.y / scale[1]).to_i,
                                  e.button, e.modifiers
            when Dungeon::Core::Events::MouseButtondownEvent
              scale = self.context.scale
              self.emit :mousedown, (e.x / scale[0]).to_i,
                                    (e.y / scale[1]).to_i,
                                    e.button, e.modifiers
            end
          end

          self.emit :end
        end
      end

      after :interval do
        self.emit :draw
        get_var("ctx").present
      end

      def self.run!
        self.new.tap { |o| o.emit :event_loop }
      end

      def open_context title, width, height
        @context = Dungeon::Core::SDLContext.open(title, width, height)
      end
    end
  end
end
