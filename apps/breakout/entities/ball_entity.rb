require "matrix"

class BallEntity < Dungeon::Core::Entity
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::MovementAspect
  include Dungeon::Common::RestrictAspect
  include Dungeon::Common::CollisionAspect

  attr_reader :mode
  attr_reader :player

  DEFAULT_SPEED = 128
  STARTING_ANGLE = (3.0 * Math::PI / 4.0)
  ANGLE_RESTRICT = [
    (-1.0 * Math::PI / 6.0),
    (-5.0 * Math::PI / 6.0),
  ]

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
      @mode = nil
      self.x_speed = DEFAULT_SPEED * Math.cos(STARTING_ANGLE)
      self.y_speed = DEFAULT_SPEED * Math.sin(STARTING_ANGLE)
    end
  end

  on :bump do |e,mtv|
    self.x_speed = -self.x_speed if mtv[0] != 0

    if mtv[1] != 0
      unless e.nil?
        v_1 = Vector[(self.x + (self.width / 2)), (self.y + (self.height / 2))]
        v_2 = Vector[(e.x + (e.width / 2)), (if mtv[1] < 0
          e.y + (e.height / 2) + 32
        else
          e.y + (e.height / 2) - 32
        end)]

        norm = (v_1 - v_2).tap { |o| o[0] = o[0] }.normalize
        d = Vector[ self.x_speed, self.y_speed ]
        r = d - (2 * d.dot(norm) * norm)

        atan2 = Math.atan2(r[1], r[0])

        if atan2 < ANGLE_RESTRICT.min
          self.y_speed = DEFAULT_SPEED * Math.cos(ANGLE_RESTRICT.min)
          self.x_speed = DEFAULT_SPEED * Math.sin(ANGLE_RESTRICT.min)
        elsif atan2 > ANGLE_RESTRICT.max
          self.y_speed = DEFAULT_SPEED * Math.cos(ANGLE_RESTRICT.max)
          self.x_speed = DEFAULT_SPEED * Math.sin(ANGLE_RESTRICT.max)
        else
          self.x_speed = r[0]
          self.y_speed = r[1]
        end
      else
        self.y_speed = -self.y_speed
      end
    end

    e.emit :ball_collision if e.is_a? BlockEntity
  end

  def player= value
    @player = value
    self.x = @player.x + (@player.width / 2) - (self.width / 2)
    self.y = @player.y - 12
  end
end
