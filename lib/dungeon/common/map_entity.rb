require "forwardable"

require "dungeon/core/map"
require "dungeon/core/collision"
require "dungeon/core/savable"
require "dungeon/common/collection_entity"
require "dungeon/common/tilelayer_entity"
require "dungeon/common/imagelayer_entity"

module Dungeon
  module Common
    class MapEntity < CollectionEntity
      extend Forwardable
      def_delegators :@map, :width, :width=,
                            :height, :height=,
                            :background, :background=

      attr_reader :map

      after :interval do
        self.emit :pre_collision, @collision
        self.emit :post_collision, @collision
        @collision.clear
      end

      on :draw do
        self.ctx.color = @map.background
        self.ctx.clear
      end

      def map= value
        self.remove_all

        @map = unless value.is_a? Dungeon::Core::Map
          Dungeon::Core::Map.load value.to_s
        else
          value
        end

        @collision = Dungeon::Core::Collision.new(@map.width.to_i,
                                                  @map.height.to_i)

        @map.entities.flatten.reverse.each do |e|
          self.add_front Dungeon::Core::Savable.load(e, self.ctx)
        end

        self.emit :mapupdate
      end
    end
  end
end
