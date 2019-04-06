require "dungeon/core/assets"
require "dungeon/common/collection_entity"
require "dungeon/common/map_entity"
require "dungeon/test_entity"

module Dungeon
  class RootEntity < Dungeon::Common::CollectionEntity
    on :new do
      self.add(Dungeon::Common::MapEntity.new(Dungeon::Core::Assets["map"]))

      self.add(TestEntity.new.tap do |o|
        o.x = (VIEW_WIDTH / 2) - 16
        o.y = (VIEW_HEIGHT / 2) - 16
      end)
    end

    after :interval do
      self.emit :draw
      get_var("ctx").present
    end
  end
end
