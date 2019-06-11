require "matrix"

STAGE_WIDTH = 272
STAGE_HEIGHT = 288

SCALE_FACTOR = 2
WINDOW_WIDTH = STAGE_WIDTH * SCALE_FACTOR
WINDOW_HEIGHT = STAGE_HEIGHT * SCALE_FACTOR
VIEW_WIDTH = WINDOW_WIDTH / SCALE_FACTOR
VIEW_HEIGHT = WINDOW_HEIGHT / SCALE_FACTOR

class Application < Dungeon::Core::ApplicationBase
  def run!
    # open_profile_system
    open_video_system("test", WINDOW_WIDTH, WINDOW_HEIGHT) do |video|
      video.context.scale = SCALE_FACTOR
      video.context.scale_quality = 0
      video.init_assets "apps/breakout/assets/manifest.yaml"
    end
    #open_console_system

    let_var("state", State.new) do
      event_loop RootEntity
    end
  end
end

class State
  attr_accessor :lives

  def initialize
    @lives = 3
  end
end

class RootEntity < Dungeon::Common::CollectionEntity
  on :new do
    self.add(StageEntity.new.tap { |o| o.map = "stage1" })
  end

  on :gameover do
    self.add(StageEntity.new.tap { |o| o.map = "stage1" })
  end

  after :interval do
    self.emit :draw
    get_var("ctx").present
  end
end

class StageEntity < Dungeon::Common::MapEntity
  include Dungeon::Common::EditorAspect
  include Dungeon::Common::TimerAspect
  
  on :mapupdate do
    self.add(@player = PlayerEntity.new.tap do |o|
      o.x = ((self.width - 8 - o.width) / 2) + 8
      o.y = self.height - 32

      o.x_restrict = (8..(self.width - o.width - 8))
    end)

    self.add(BallEntity.new.tap do |o|
      o.player = @player
      o.x_restrict = (8..(self.width - o.width - 8))
      o.y_restrict = (8..)
    end)
  end

  on :ballout do
    set_timer(1000) do
      state = get_var("state")
      if state.lives <= 0
        self.broadcast(:gameover)
        self.remove
      else
        state.lives -= 1

        self.add(BallEntity.new.tap do |o|
          o.player = @player
          o.x_restrict = (8..(self.width - o.width - 8))
          o.y_restrict = (8..)
        end)
      end
    end
  end

  after :draw do |ctx|
    sprite = Dungeon::Core::Assets["ball"]
    get_vars([ "state", "ctx" ]).tap do |state, ctx|
      state.lives.to_i.times do |i|
        ctx.draw_sprite sprite.texture, (16 + (i * 12)), self.height - 12, 0, 0, 8, 8
      end
    end
  end
end

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

    self.sprite = "player"

    self.controls["up"]["speed"] = 0
    self.controls["down"]["speed"] = 0
  end
end

class BlockEntity < Dungeon::Core::Entity
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::DrawAspect
  include Dungeon::Common::MovementAspect

  include Dungeon::Core::Savable

  savable [ :x, :y, :sprite_tag ]

  on :new do
    self.width = 16
    self.height = 8

    self.sprite = "block"
  end

  on :ball_collision do
    self.remove
  end
end

class BallEntity < Dungeon::Core::Entity
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::MovementAspect
  include Dungeon::Common::RestrictAspect
  include Dungeon::Common::CollisionAspect

  attr_accessor :player

  DEFAULT_SPEED = 128
  STARTING_ANGLE = (3.0 * Math::PI / 4.0)
  ANGLE_RESTRICT = [
    (-1.0 * Math::PI / 6.0),
    (-5.0 * Math::PI / 6.0),
  ]

  on :new do |player|
    self.width = 8
    self.height = 8

    self.sprite = "ball"
  end

  on :interval do
    unless @started
      unless @player.nil?
        self.x = @player.x + (3 * (@player.width / 4)) - (self.width / 2)
        self.y = @player.y - 12
      end
    else
      if self.y > STAGE_HEIGHT
        self.broadcast(:ballout)
        self.remove
      end
    end
  end

  on :keydown do |key|
    if not @started and key == "space"
      @started = true

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
end
