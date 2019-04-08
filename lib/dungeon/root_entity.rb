require "dungeon/core/assets"
require "dungeon/common/collection_entity"
require "dungeon/common/map_entity"
require "dungeon/test_entity"
require "dungeon/foo_entity"

module Dungeon
  class RootEntity < Dungeon::Common::CollectionEntity
    on :new do
      self.add(Dungeon::Common::MapEntity.new(Dungeon::Core::Assets["map"]).tap do |map|
        map.add(TestEntity.new.tap do |o|
          o.x = (VIEW_WIDTH / 2) - 16
          o.y = (VIEW_HEIGHT / 2) - 16
        end)

        map.add(FooEntity.new.tap do |o|
          o.x = (VIEW_WIDTH / 2) - 8
          o.y = (VIEW_HEIGHT / 2) - 8
        end)
      end)
    end

    after :interval do
      self.emit :draw
      get_var("ctx").present
    end
  end
end
