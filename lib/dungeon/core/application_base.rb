require "dungeon/core/video_system"
require "dungeon/core/event_system"
require "dungeon/core/profile_system"
require "dungeon/core/console_system"

module Dungeon
  module Core
    class ApplicationBase
      attr_reader :systems
      attr_reader :root

      def self.run!
        self.new.tap do |o|
          begin
            o.run!
          ensure
            o.close
          end
        end
      end

      def initialize
        @system_stack = []
        @systems = {}
      end

      def run!
      end

      def open_profile_system *args
        push_system "profile", ProfileSystem.open(*args)
        yield @systems["profile"] if block_given?
      end

      def open_video_system *args
        push_system "video", VideoSystem.open(*args)
        yield @systems["video"] if block_given?
      end

      def open_event_system *args
        push_system "event", EventSystem.open(*args)
        yield @systems["event"] if block_given?
      end

      def open_console_system *args
        push_system "console", ConsoleSystem.open(self, *args)
        yield @systems["console"] if block_given?
      end

      def event_loop destination_klass = nil
        @root = if destination_klass.is_a? Array
          destination_klass = destination_klass.dup
          klass = destination_klass.shift
          klass.new(*destination_klass)
        elsif not destination_klass.nil?
          destination_klass.new
        elsif not @root.nil?
          @root
        else
          raise "Missing Root Entity"
        end

        open_event_system unless @systems.has_key? "event"

        let_vars({
          "ctx" => @systems.has_key?("video") ? @systems["video"].context : nil,
          "events" => @systems["event"],
        }) do
          @systems["event"].each(60) do |e|
            case e
            when ConsoleSystem::ConsoleEvent
              @root.emit :console, e.args
              e.release
            when EventSystem::KeyupEvent
              @root.emit :keyup, e.key, e.modifiers
            when EventSystem::KeydownEvent
              @root.emit :keydown, e.key, e.modifiers
            when EventSystem::KeyrepeatEvent
              @root.emit :keyrepeat, e.key, e.modifiers
            when EventSystem::TextInputEvent
              @root.emit :textinput, e.text
            when EventSystem::IntervalEvent
              @root.emit :interval, e.dt
            when EventSystem::MouseMoveEvent
              scale = @systems.has_key?("video") ?
                @systems["video"].context.scale : [ 1, 1 ]
              @root.emit :mousemove, (e.x / scale[0]).to_i,
                                     (e.y / scale[1]).to_i,
                                     e.modifiers
            when EventSystem::MouseButtonupEvent
              scale = @systems.has_key?("video") ?
                @systems["video"].context.scale : [ 1, 1 ]
              @root.emit :mouseup, (e.x / scale[0]).to_i,
                                   (e.y / scale[1]).to_i,
                                   e.button, e.modifiers
            when EventSystem::MouseButtondownEvent
              scale = @systems.has_key?("video") ?
                @systems["video"].context.scale : [ 1, 1 ]
              @root.emit :mousedown, (e.x / scale[0]).to_i,
                                     (e.y / scale[1]).to_i,
                                     e.button, e.modifiers
            end
          end
        end
      end

      def push_system name, system
        @system_stack.push system
        @systems[name.to_s] = system
      end

      def close
        @system_stack.reverse_each { |e| e.close }
        @system_stack.clear
        @systems.clear
      end
    end
  end
end
