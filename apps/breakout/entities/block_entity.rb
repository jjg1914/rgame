class BlockEntity < Dungeon::Core::Entity
  include Dungeon::Common::CollisionAspect
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::DrawAspect
  include Dungeon::Common::MovementAspect

  include Dungeon::Core::Savable

  savable [ :x, :y, :sprite_tag ]

  on :new do
    self.width = 16
    self.height = 8

    self.solid = true

    self.sprite = "block"
  end

  on :ball_collision do
    self.remove
  end
end
