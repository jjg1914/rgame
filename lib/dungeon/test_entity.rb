require "dungeon/entity"
require "dungeon/draw_aspect"
require "dungeon/sprite_aspect"
require "dungeon/control_aspect"
require "dungeon/position_aspect"
require "dungeon/movement_aspect"

module Dungeon
  class TestEntity < Dungeon::Entity
    include Dungeon::DrawAspect
    include Dungeon::SpriteAspect
    include Dungeon::ControlAspect
    include Dungeon::PositionAspect
    include Dungeon::MovementAspect

    on :new do
      self.width = 16
      self.height = 16

      self.sprite = "model"
      self.sprite_translate = -8
    end
  end
end
