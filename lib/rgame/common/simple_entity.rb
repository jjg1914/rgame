# frozen_string_literal: true

require "rgame/core/entity"
require "rgame/common/input_aspect"
require "rgame/common/position_aspect"
require "rgame/common/movement_aspect"
require "rgame/common/sprite_aspect"
require "rgame/common/collision_aspect"

module RGame
  module Common
    class SimpleEntity < RGame::Core::Entity
      include RGame::Common::PositionAspect
      include RGame::Common::MovementAspect
      include RGame::Common::SpriteAspect
      include RGame::Common::CollisionAspect
      include RGame::Common::InputAspect
    end
  end
end
