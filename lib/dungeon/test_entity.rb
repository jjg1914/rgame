require "dungeon/entity"
require "dungeon/draw_aspect"
require "dungeon/control_aspect"
require "dungeon/position_aspect"
require "dungeon/movement_aspect"

module Dungeon
  class TestEntity < Dungeon::Entity
    include Dungeon::DrawAspect
    include Dungeon::ControlAspect
    include Dungeon::PositionAspect
    include Dungeon::MovementAspect
  end
end
