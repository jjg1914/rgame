require "dungeon/core/map"
require "dungeon/core/assets"
require "dungeon/core/collision"
require "dungeon/common/collection_entity"
require "dungeon/common/tilelayer_entity"
require "dungeon/common/imagelayer_entity"

module Dungeon
  module Common
    class MapEntity < CollectionEntity
      on :new do |map|
        @map = unless map.is_a? Dungeon::Core::Map
          Dungeon::Core::Assets[map.to_s]
        else
          map
        end
        @collision = Dungeon::Core::Collision.new((@map.width * @map.tile_width),
                                                  (@map.height * @map.tile_height))

        @map.layers.each do |e|
          if e.is_a? Dungeon::Core::Map::Tilelayer
            self.add(TilelayerEntity.new(e, @map.tileset)) unless @map.tileset.nil?
          elsif e.is_a? Dungeon::Core::Map::Imagelayer
            self.add(ImagelayerEntity.new(e.image))
          elsif e.is_a? Dungeon::Core::Map::Objectgroup
            self.add_bulk e.load_entities
          end
        end
      end

      after :interval do |p|
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
    end
  end
end
