# frozen_string_literal: true

require "forwardable"

require "rgame/core/map"
require "rgame/core/collision"
require "rgame/core/savable"
require "rgame/common/collection_entity"
require "rgame/common/tilelayer_entity"
require "rgame/common/imagelayer_entity"

module RGame
  module Common
    class MapEntity < CollectionEntity
      extend Forwardable
      def_delegators :@map,
                     :width,
                     :width=,
                     :height,
                     :height=,
                     :background,
                     :background=

      attr_reader :map

      after "interval" do
        self.emit "collision_mark", @collision
        self.emit "collision_sweep", @collision
        self.emit "collision_resolve", @collision
        @collision.clear
      end

      on "draw" do
        self.ctx.renderer.color = @map.background
        self.ctx.renderer.clear
      end

      def map= value
        self.remove_all

        @map = if value.is_a? RGame::Core::Map
          value
        else
          RGame::Core::Map.load value.to_s
        end

        @collision = RGame::Core::Collision.new(@map.width.to_i,
                                                @map.height.to_i)

        @map.entities.flatten.reverse.each do |e|
          self.add_front RGame::Core::Savable.load(e, self.ctx)
        end

        self.emit "mapupdate"
      end
    end
  end
end
