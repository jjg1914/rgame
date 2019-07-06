require "dungeon/runtime"

require "matrix"

STAGE_WIDTH = 272
STAGE_HEIGHT = 288

SCALE_FACTOR = 2
WINDOW_WIDTH = STAGE_WIDTH * SCALE_FACTOR
WINDOW_HEIGHT = STAGE_HEIGHT * SCALE_FACTOR
VIEW_WIDTH = WINDOW_WIDTH / SCALE_FACTOR
VIEW_HEIGHT = WINDOW_HEIGHT / SCALE_FACTOR

class State
  attr_reader :lives
  attr_reader :balls
  attr_accessor :score

  def initialize
    @balls = 1
    @lives = 5
    @score = 0
  end

  def lives= value
    @lives = [ [ value.to_i, 0 ].max, 99 ].min
  end

  def balls= value
    @balls = [ [ value.to_i, 0 ].max, 4 ].min
  end
end

class Dungeon::Common::RootEntity
  before :event_loop do
    open_context "Breakout", WINDOW_WIDTH, WINDOW_HEIGHT
    context.scale = SCALE_FACTOR
    context.scale_quality = 0
  end

  on :start do
    self.add(StageEntity.new.tap { |o| o.map = "stage1" })
  end

  on :gameover do
    get_var("state").tap { |o| o.reset unless o.nil? }
    self.add(StageEntity.new.tap { |o| o.map = "stage1" })
  end
end

class StageEntity < Dungeon::Common::MapEntity
  include Dungeon::Common::EditorAspect
  include Dungeon::Common::TimerAspect

  on :mapupdate do
    @state = State.new

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

  on :ballin do
    @state.balls += 1

    self.add(BallEntity.new.tap do |o|
      o.player = @player
      o.x_restrict = (8..(self.width - o.width - 8))
      o.y_restrict = (8..)
    end)
  end

  on :ballout do
    @state.balls -= 1
    if @state.balls == 0
      set_timer(1000) do
        if @state.lives <= 0
          self.broadcast(:gameover)
          self.remove
        else
          clear_timer @wide_timer unless @wide_timer.nil?
          @player.sprite = "player"

          @state.lives -= 1

          self.add(BallEntity.new.tap do |o|
            o.player = @player
            o.x_restrict = (8..(self.width - o.width - 8))
            o.y_restrict = (8..)
          end)
        end
      end
    end
  end

  on :livesup do |count|
    @state.lives + count
  end

  on :score do |value|
    @state.score += value
  end

  on :widen_player do
    clear_timer @wide_timer unless @wide_timer.nil?
    @wide_timer = (set_timer(10000) do
      @player.sprite = "player"
      @wide_timer = nil
    end)
    @player.sprite = "player_wide"
    if @player.x + @player.width >= self.width - 8
      @player.x = self.width - @player.width - 8
    end
  end

  after :draw do |ctx|
    sprite = Dungeon::Core::Sprite.load "ball"
    get_var("ctx").tap do |ctx|
      if @state.lives > 5
        if @cache_lives != @state.lives
          @lives_image.free unless @lives_image.nil?
          @cache_lives = @state.lives

          ctx.font = "PressStart2P-Regular:8"
          ctx.color = 0xFFFFFF

          @lives_image = ctx.create_text @cache_lives.to_s.rjust(2, " ") + "x"
        end

        ctx.source = @lives_image
        ctx.draw_image self.width - @lives_image.width - 20, 12

        ctx.source = sprite.image
        ctx.draw_image self.width - 20, 11, 0, 0, 8, 8
      else
        @lives_image.free unless @lives_image.nil?
        ctx.source = sprite.image
        @state.lives.to_i.times do |i|
          ctx.draw_image self.width - (8 + ((i + 1) * 12)), 11, 0, 0, 8, 8
        end
      end

      if @cache_score != @state.score
        @score_image.free unless @score_image.nil?
        @cache_score = @state.score

        ctx.font = "PressStart2P-Regular:8"
        ctx.color = 0xFFFFFF
        @score_image = ctx.create_text @cache_score.to_s.rjust(6, "0")
      end

      ctx.source = @score_image
      ctx.draw_image 12, 12
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
    self.sprite = "block"
  end

  on :ball_collision do
    self.broadcast :score, 100
    PowerupEntity.generate.tap do |o|
      unless o.nil?
        o.x = self.x
        o.y = self.y
        self.parent.add(o)
      end
    end
    self.remove
  end
end

class BallEntity < Dungeon::Core::Entity
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::MovementAspect
  include Dungeon::Common::CollisionAspect
  include Dungeon::Common::RestrictAspect
  include Dungeon::Common::TimerAspect

  attr_accessor :player

  DEFAULT_SPEED = 112
  STARTING_ANGLE = (3.0 * Math::PI / 4.0)
  ANGLE_RESTRICT_UP = [
    (-1.0 * Math::PI / 8.0),
    (-7.0 * Math::PI / 8.0),
  ]
  ANGLE_RESTRICT_DOWN = [
    (1.0 * Math::PI / 4.0),
    (3.0 * Math::PI / 4.0),
  ]

  on :new do |player|
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

    if mtv[1] != 0 and (self.sprite_tag != "power_ball" or not e.is_a?(BlockEntity))
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

        if self.y_speed > 0
          if atan2 < ANGLE_RESTRICT_UP.min
            self.angle = ANGLE_RESTRICT_UP.min
          elsif atan2 > ANGLE_RESTRICT_UP.max
            self.angle = ANGLE_RESTRICT_UP.max
          else
            self.angle = atan2
          end
        else
          if atan2 < ANGLE_RESTRICT_DOWN.min
            self.angle = ANGLE_RESTRICT_DOWN.min
          elsif atan2 > ANGLE_RESTRICT_DOWN.max
            self.angle = ANGLE_RESTRICT_DOWN.max
          else
            self.angle = atan2
          end
        end
      else
        self.y_speed = -self.y_speed
      end
    end

    e.emit :ball_collision if e.is_a? BlockEntity
  end

  on :slow do
    clear_timer @slow_timer unless @slow_timer.nil?
    @slow_timer = set_timer(5000) do
      self.speed = DEFAULT_SPEED
      @slow_timer = nil
    end
    self.speed = 0.5 * DEFAULT_SPEED
  end

  on :power_ball do
    clear_timer @power_timer unless @power_timer.nil?
    @power_timer = set_timer(5000) do
      self.sprite_tag = "default"
      @power_timer = nil
    end
    self.sprite_tag = "power_ball"
  end
end

class PowerupEntity < Dungeon::Core::Entity
  FREQUENCIES = [
    [ "power_ball", 1 ],
    [ "1up", 1 ],
    [ "extra_ball", 1 ],
    [ "wide_paddle", 1 ],
    [ "slow_ball", 1 ],
    [ nil, 30 ],
  ]

  def self.generate
    weight = FREQUENCIES.map { |e| e[1] }.sum
    table = FREQUENCIES.map do |e|
      [ e[0], e[1].to_f / weight.to_f]
    end.reduce([]) do |m,v|
      m + [ [ v[0], m.last&.last.to_f + v[1] ] ]
    end

    value = rand
    index = table.find_index { |e| e[1] >= value }.to_i
    unless table[index].first.nil?
      self.new.tap { |o| o.sprite_tag = table[index].first }
    end
  end

  include Dungeon::Common::CollisionAspect
  include Dungeon::Common::SpriteAspect
  include Dungeon::Common::PositionAspect
  include Dungeon::Common::MovementAspect

  on :new do
    self.sprite = "powerup"
    self.y_speed = 64
    self.solid = false
    self.sprite_tag = "power_ball"
  end

  on :collision do |e, mtv|
    if e.is_a? PlayerEntity
      case self.sprite_tag
      when "1up"
        self.broadcast(:livesup, 1)
      when "extra_ball"
        self.broadcast(:ballin)
      when "wide_paddle"
        self.broadcast(:widen_player)
      when "slow_ball"
        self.broadcast(:slow)
      when "power_ball"
        self.broadcast(:power_ball)
      end
      self.remove
    end
  end
end
