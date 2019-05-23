require "forwardable"

require "dungeon/core/map"
require "dungeon/core/assets"
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
        let_var("collision", @collision) do
          self.emit :pre_collision
          self.emit :post_collision
          @collision.clear
        end
      end

      on :draw do
        get_var("ctx").tap do |ctx|
          ctx.color = @map.background
          ctx.clear
        end
      end

      def map= value
        self.remove_all

        @map = unless value.is_a? Dungeon::Core::Map
          Dungeon::Core::Assets[value.to_s]
        else
          value
        end

        @collision = Dungeon::Core::Collision.new(@map.width.to_i,
                                                  @map.height.to_i)

        @map.entities.flatten.reverse.each do |e|
          self.add_front Dungeon::Core::Savable.load(e)
        end

        self.emit :mapupdate
      end
    end
  end
end
