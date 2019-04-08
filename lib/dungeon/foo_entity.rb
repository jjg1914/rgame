require "dungeon/core/entity"
require "dungeon/common/collision_aspect"
require "dungeon/common/draw_aspect"
require "dungeon/common/position_aspect"

module Dungeon
  class FooEntity < Dungeon::Core::Entity
    include Dungeon::Common::CollisionAspect
    include Dungeon::Common::DrawAspect
    include Dungeon::Common::PositionAspect

    on :new do
      self.width = 16
      self.height = 16
    end
  end
end
