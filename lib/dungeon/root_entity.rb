require "dungeon/collection_entity"
require "dungeon/test_entity"

module Dungeon
  class RootEntity < Dungeon::CollectionEntity
    on :new do |ctx|
      @ctx = ctx

      self.add(TestEntity.new.tap do |o|
        o.x = 320 - 16
        o.y = 240 - 16
      end)
    end

    after :interval do
      @ctx.color = 0x888888
      @ctx.clear
      self.emit :draw, @ctx
      @ctx.present
    end
  end
end
