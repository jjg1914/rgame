require "dungeon/core/map"
require "dungeon/core/assets"
require "dungeon/common/collection_entity"
require "dungeon/common/tilelayer_entity"

module Dungeon
  module Common
    class MapEntity < CollectionEntity
      on :new do |map|
        @map = map

        @map.layers.each do |e|
          self.add(TilelayerEntity.new(e, Dungeon::Core::Assets[@map.tileset]))
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
