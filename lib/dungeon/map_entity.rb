require "dungeon/collection_entity"
require "dungeon/tilelayer_entity"
require "dungeon/map"
require "dungeon/assets"

module Dungeon
  class MapEntity < Dungeon::CollectionEntity
    on :new do |ctx, map|
      @map = map

      @map.layers.each do |e|
        self.add(TilelayerEntity.new(ctx, e, Assets[@map.tileset]))
      end
    end

    on :draw do |ctx|
      ctx.color = @map.background
      ctx.clear
    end
  end
end
