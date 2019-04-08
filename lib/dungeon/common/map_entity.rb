require "dungeon/core/map"
require "dungeon/core/assets"
require "dungeon/core/collision"
require "dungeon/common/collection_entity"
require "dungeon/common/tilelayer_entity"

module Dungeon
  module Common
    class MapEntity < CollectionEntity
      on :new do |map|
        @map = map
        @collision = Dungeon::Core::Collision.new((map.width * map.tile_width),
                                                  (map.height * map.tile_height))

        @map.layers.each do |e|
          self.add(TilelayerEntity.new(e, Dungeon::Core::Assets[@map.tileset]))
        end
      end

      around :interval do |p|
        let_var("collision", @collision) do
          p.call
          self.emit :collision
          @collision.clear
        end
      end

      on :draw do
        get_var("ctx").tap do |ctx|
          ctx.color = @map.background
          ctx.clear
        end
      end
    end
  end
end
