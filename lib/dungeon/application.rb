require "dungeon/core/application_base"
require "dungeon/root_entity"

module Dungeon
  WINDOW_WIDTH = 640
  WINDOW_HEIGHT = 576
  SCALE_FACTOR = 4
  VIEW_WIDTH = WINDOW_WIDTH / SCALE_FACTOR
  VIEW_HEIGHT = WINDOW_HEIGHT / SCALE_FACTOR

  class Application < Dungeon::Core::ApplicationBase
    def run!
      # open_profile_system
      open_video_system("test", WINDOW_WIDTH, WINDOW_HEIGHT) do |video|
        video.context[Dungeon::Core::SDL2::SDL_HINT_RENDER_SCALE_QUALITY] = 0
        video.context.scale = SCALE_FACTOR
        video.init_assets "assets/manifest.yaml"
      end

      event_loop RootEntity
    end
  end
end
