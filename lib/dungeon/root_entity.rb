require "dungeon/collection_entity"
require "dungeon/test_entity"
require "dungeon/map_entity"

module Dungeon
  class RootEntity < Dungeon::CollectionEntity
    on :new do |ctx|
      @ctx = ctx

      self.add(MapEntity.new(ctx, Assets["map"]))

      self.add(TestEntity.new.tap do |o|
        o.x = (VIEW_WIDTH / 2) - 16
        o.y = (VIEW_HEIGHT / 2) - 16
      end)
    end

    after :interval do
      self.emit :draw, @ctx
      @ctx.present
    end
  end
end
