require "dungeon/core/entity"
require "dungeon/common/draw_aspect"
require "dungeon/common/sprite_aspect"
require "dungeon/common/control_aspect"
require "dungeon/common/position_aspect"
require "dungeon/common/movement_aspect"

module Dungeon
  class TestEntity < Dungeon::Core::Entity
    include Dungeon::Common::DrawAspect
    include Dungeon::Common::SpriteAspect
    include Dungeon::Common::ControlAspect
    include Dungeon::Common::PositionAspect
    include Dungeon::Common::MovementAspect

    on :new do
      self.width = 16
      self.height = 16

      self.sprite = "model"
      self.sprite_translate = -8
    end
  end
end
