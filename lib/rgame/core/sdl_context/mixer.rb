# frozen_string_literal: true

require "rgame/core/sdl"
require "rgame/core/sdl_context/chunk"
require "rgame/core/sdl_context/sound_handle"

module RGame
  module Core
    class SDLContext
      class Mixer
        attr_accessor :channel
        attr_reader :max_channels

        def initialize
          @channels = {}
          @channel = -1
          @max_channels = SDL2Mixer.Mix_AllocateChannels(-1)

          # this will get GC'd if we dont save it to an instance variable
          @_channel_finished = self.method :_channel_finished
          SDL2Mixer.Mix_ChannelFinished(@_channel_finished)

          @chunk_cache = ChunkCache.new
        end

        def max_channels= value
          return if value == @max_channels

          SDL2Mixer.Mix_AllocateChannels value.to_i
          @max_channels = value
        end

        def play_effect chunk, loops = 0
          return unless @max_channels.positive?

          chunk = if chunk.is_a? Chunk
            value
          else
            @chunk_cache[chunk.to_s]
          end
          channel = SDL2Mixer.Mix_PlayChannelTimed(@channel,
                                                   chunk.chunk,
                                                   loops, -1)

          SoundHandle.new(channel).tap { |o| @channels[channel] = o }
        end

        private

        def _channel_finished channel
          @channels[channel]&.invalidate!
          @channels.delete channel
        end
      end
    end
  end
end
