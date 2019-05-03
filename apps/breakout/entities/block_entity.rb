class BlockEntity < Dungeon::Core::Entity
  include Dungeon::Common::CollisionAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::DrawAspect
  include Dungeon::Common::MovementAspect

  on :new do
    self.width = 32
    self.height = 8

    self.solid = true

    self.fill_color = "bright_red"
    self.stroke_color = "red"
  end

  on :post_collision do
    self.remove if @ball_collision
  end

  on :collision do |e,mtv|
    @ball_collision = e.is_a? BallEntity
  end
end
