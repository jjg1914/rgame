# frozen_string_literal: true

require "rgame/core/sdl"

module RGame
  module Core
    class SDLContext
      class SoundHandle
        def initialize channel
          @channel = channel
          @valid = true
          self.volume = 64
        end

        def valid?
          @valid
        end

        def invalidate!
          @valid = false
        end

        def volume= value
          throw "invalid" unless self.valid?

          SDL2Mixer.Mix_Volume @channel, value
        end

        def volume
          throw "invalid" unless self.valid?

          SDL2Mixer.Mix_Volume @channel, -1
        end

        def halt
          throw "invalid" unless self.valid?

          SDL2Mixer.Mix_HaltChannel @channel
        end

        def pause
          throw "invalid" unless self.valid?

          SDL2Mixer.Mix_Pause @channel
        end

        def resume
          throw "invalid" unless self.valid?

          SDL2Mixer.Mix_Resume @channel
        end

        def paused?
          throw "invalid" unless self.valid?

          SDL2Mixer.Mix_Paused(@channel) > 1
        end
      end
    end
  end
end
