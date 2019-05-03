class PlayerEntity < Dungeon::Core::Entity
  include Dungeon::Common::CollisionAspect
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::Control4WayAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::MovementAspect
  include Dungeon::Common::RestrictAspect

  on :new do
    self.width = 32
    self.height = 8

    self.solid = true

    self.sprite = "player"

    self.controls["up"]["speed"] = 0
    self.controls["down"]["speed"] = 0
  end
end
