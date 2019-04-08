require "dungeon/core/video_system"
require "dungeon/core/event_system"
require "dungeon/core/profile_system"

module Dungeon
  module Core
    class ApplicationBase
      attr_reader :systems

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

      def event_loop destination_klass
        let_var("ctx", @systems.has_key?("video") ? @systems["video"].context : nil ) do
          destination = destination_klass.new
          open_event_system unless @systems.has_key? "event"

          @systems["event"].each(60) do |e|
            case e
            when EventSystem::KeyupEvent
              destination.emit :keyup, e.key
            when EventSystem::KeydownEvent
              destination.emit :keydown, e.key
            when EventSystem::IntervalEvent
              destination.emit :interval, e.dt
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
