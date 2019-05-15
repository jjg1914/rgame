require "matrix"

class BallEntity < Dungeon::Core::Entity
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::MovementAspect
  include Dungeon::Common::RestrictAspect
  include Dungeon::Common::CollisionAspect

  attr_reader :mode
  attr_reader :player

  on :new do |player|
    @mode = "init"
    @player = player

    self.width = 8
    self.height = 8
    self.solid = true

    self.sprite = "ball"
  end

  on :interval do
    if self.mode == "init" and not @player.nil?
      self.x = @player.x + (3 * (@player.width / 4)) - (self.width / 2)
      self.y = @player.y - 12
    end
  end

  on :keydown do |key|
    if key == "space"
      @mode = "go"
      self.y_speed = -128
      self.x_speed = 64
    end
  end

  on :bump do |e,mtv|
    self.x_speed = -self.x_speed if mtv[0] != 0

    if mtv[1] != 0
      unless e.nil?
        v_1 = Vector[(self.x + (self.width / 2)), (self.y + (self.height / 2))]
        v_2 = Vector[(e.x + (e.width / 2)), (if mtv[1] < 0
          e.y + (e.height / 2) + 48
        else
          e.y + (e.height / 2) - 48
        end)]

        norm = (v_1 - v_2).tap { |o| o[0] = -o[0] }.normalize
        d = Vector[ self.x_speed, self.y_speed ]
        r = d - (2 * d.dot(norm) * norm)

        self.x_speed = r[0]
        self.y_speed = r[1]
      else
        self.y_speed = -self.y_speed
      end
    end
  end

  def player= value
    @player = value
    self.x = @player.x + (@player.width / 2) - (self.width / 2)
    self.y = @player.y - 12
  end
end
