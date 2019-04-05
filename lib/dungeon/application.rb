require "dungeon/root_entity"
require "dungeon/video_system"
require "dungeon/event_system"
#require "dungeon/profile_system"

module Dungeon
  WINDOW_WIDTH = 640
  WINDOW_HEIGHT = 576
  SCALE_FACTOR = 4
  VIEW_WIDTH = WINDOW_WIDTH / SCALE_FACTOR
  VIEW_HEIGHT = WINDOW_HEIGHT / SCALE_FACTOR

  class Application

    def self.run!
      self.new.tap { |o| o.run! }
    end

    def run!
      open_systems([
        #ProfileSystem,
        [ VideoSystem, "test", WINDOW_WIDTH, WINDOW_HEIGHT ],
        EventSystem,
      ]) do |video, event|
        video.context[SDL2::SDL_HINT_RENDER_SCALE_QUALITY] = 0
        video.context.scale = SCALE_FACTOR
        video.init_assets "assets/manifest.yaml"

        event_loop RootEntity.new(video.context), event
      end
    end

    def event_loop destination, source
      source.each(60) do |e|
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
