WINDOW_WIDTH = 640
WINDOW_HEIGHT = 576
SCALE_FACTOR = 2
VIEW_WIDTH = WINDOW_WIDTH / SCALE_FACTOR
VIEW_HEIGHT = WINDOW_HEIGHT / SCALE_FACTOR

require "entities/root_entity"

class Application < Dungeon::Core::ApplicationBase
  def run!
    # open_profile_system
    open_video_system("test", WINDOW_WIDTH, WINDOW_HEIGHT) do |video|
      video.context.scale = SCALE_FACTOR
      video.context.scale_quality = 0
      video.init_assets "apps/breakout/assets/manifest.yaml"
    end
    open_console_system

    event_loop RootEntity
  end
end
