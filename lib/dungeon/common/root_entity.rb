# frozen_string_literal: true

require "dungeon/core/env"
require "dungeon/core/events"
require "dungeon/core/sdl_context"
require "dungeon/common/stack_entity"

module Dungeon
  module Common
    class RootEntity < StackEntity
      class WindowConfig
        attr_accessor :title
        attr_accessor :size
        attr_writer :mode

        def initialize
          @title = 0
          @size = [ 640, 480 ]
        end

        def mode
          if @mode.nil?
            if Dungeon::Core::Env.enable_mmap_mode?
              "mmap"
            elsif Dungeon::Core::Env.enable_software_mode?
              "software"
            else
              "window"
            end
          else
            @mode.to_s.strip.downcase
          end
        end

        def open!
          case self.mode
          when "mmap"
            self.open_mmap!
          when "software"
            self.open_software!
          else
            self.open_window!
          end
        end

        def open_window!
          Dungeon::Core::SDLContext.open_window(self.title, *self.size)
        end

        def open_software!
          Dungeon::Core::SDLContext.open_software(*self.size)
        end

        def open_mmap!
          Dungeon::Core::SDLContext.open_mmap(Dungeon::Core::Env.mmap_file,
                                              *self.size)
        end
      end

      class ContextConfig
        attr_accessor :scale
        attr_reader :scale_quality

        def initialize
          @scale = 1
          @scale_quality = 1
        end

        def scale_quality= value
          @scale_quality = if value.is_a? Numeric
            [ [ value.to_i, 0 ].max, 2 ].min
          else
            case value.to_s.strip.downcase
            when "nearest"
              0
            when "linear"
              1
            when "anisotropic", "best"
              2
            else
              raise "unknown scale quality %s" % value.inspect
            end
          end
        end
      end

      class << self
        attr_reader :window
        attr_reader :context

        def inherited klass
          super
          klass.instance_exec(self) do |parent|
            @window = parent.instance_variable_get(:@window).dup
            @context = parent.instance_variable_get(:@context).dup
          end
        end
      end

      @window = WindowConfig.new
      @context = ContextConfig.new

      on :new do
        self.context.scale = self.class.context.scale
        self.context.scale_quality = self.class.context.scale_quality
      end

      after :interval do
        self.emit :draw
        self.ctx.present
      end

      def self.run!
        self.new(self.window.open!).tap do |o|
          o.instance_eval do
            emit :start
            context.each(60) { |e| event_loop_step(e) }
            emit :end
          end
        end
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
