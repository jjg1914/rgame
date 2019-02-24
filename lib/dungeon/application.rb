require "dungeon/root_entity"
require "dungeon/video_system"
require "dungeon/event_system"
require "dungeon/profile_system"

module Dungeon
  class Application
    def self.run!
      self.new.tap { |o| o.run! }
    end

    def run!
      open_systems([
        # ProfileSystem,
        [ VideoSystem, "test", 640, 480 ],
        EventSystem,
      ]) do |video, event|
        event_loop RootEntity.new(video.context), event
      end
    end

    def event_loop destination, source
      source.each do |e|
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

    def open_systems args
      p = proc do |a,input|
        if input.empty?
          yield a
        else
          if input.first.is_a? Array
            input.first.first.open(*input.first.drop(1)) do |e|
              p.call(a.concat([ e ]), input.drop(1))
            end
          else
            input.first.open do |e|
              p.call(a.concat([ e ]), input.drop(1))
            end
          end
        end
      end
      p.call([], args)
    end
  end
end
