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

  on :post_collision do
    self.remove if @ball_collision
  end

  on :collision do |e,mtv|
    @ball_collision = e.is_a? BallEntity
  end
end
