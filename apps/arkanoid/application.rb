require "rgame/runtime"

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

class RGame::Common::RootEntity
  window.title = "Arkanoid"
  window.size = [ WINDOW_WIDTH, WINDOW_HEIGHT ]

  context.scale = SCALE_FACTOR
  context.scale_quality = "nearest"

  on :start do
    self.create(RGame::Common::CollectionEntity) do |o|
      o.create(RGame::Common::ImagelayerEntity) { |u| u.image = "stage-bg"}
      o.create(RGame::Common::ImagelayerEntity) { |u| u.image = "title"}
    end
  end

  on :keydown do |key, _|
    next if self.size > 1

    case key
    when "enter", "return"
      self.create(RGame::Common::QueueEntity) do |o|
        %w[stage1 stage2].each do |e|
          o.create(StageEntity) { |u| u.map = e }
        end

        o.on(:empty) { self.parent.pop }
      end
    end
  end

  on :gameover do
    self.pop
  end
end

class StageEntity < RGame::Common::MapEntity
  include RGame::Common::EditorAspect
  include RGame::Common::TimerAspect

  on :mapupdate do
    @state = State.new

    @player = self.create(PlayerEntity) do |o|
      o.x = ((self.width - 8 - o.width) / 2) + 8
      o.y = self.height - 32

      o.x_restrict = (playable_bounds["left"]..playable_bounds["right"])
    end

    self.create(BallEntity) do |o|
      o.player = @player
      o.x_restrict = (playable_bounds["left"]..playable_bounds["right"])
      o.y_restrict = (playable_bounds["top"]..)
    end

    @blocks = self.children.count do |e|
      e.is_a?(BlockEntity) and not e.is_a?(InvincibleBlockEntity)
    end
  end

  on :ballin do
    @state.balls += 1

    self.create(BallEntity) do |o|
      o.player = @player
      o.x_restrict = (playable_bounds["left"]..playable_bounds["right"])
      o.y_restrict = (playable_bounds["top"]..)
    end
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

          self.create(BallEntity) do |o|
            o.player = @player
            o.x_restrict = (playable_bounds["left"]..playable_bounds["right"])
            o.y_restrict = (playable_bounds["top"]..)
          end
        end
      end
    end
  end

  on :livesup do |count|
    @state.lives + count
  end

  on :score do |value|
    @state.score += value
    @blocks -= 1

    set_timer(1000) { self.parent.dequeue } if @blocks.zero?
  end

  on :widen_player do
    clear_timer @wide_timer unless @wide_timer.nil?
    @wide_timer = (set_timer(10000) do
      @player.sprite = "player"
      @wide_timer = nil
    end)
    @player.sprite = "player_wide"
    if @player.x + @player.width > playable_bounds["right"]
      @player.x = self.width - playable_bounds["right"]
    end
  end

  after :draw do |ctx|
    sprite = RGame::Core::Sprite.load "ball"
    if @state.lives > 5
      if @cache_lives != @state.lives
        @lives_image.free unless @lives_image.nil?
        @cache_lives = @state.lives

        self.ctx.font = "PressStart2P-Regular:8"
        self.ctx.color = 0xFFFFFF

        @lives_image = self.ctx.create_text @cache_lives.to_s.rjust(2, " ") + "x"
      end

      self.ctx.source = @lives_image
      self.ctx.draw_image self.width - @lives_image.width - 20, 12

      self.ctx.source = sprite.image
      self.ctx.draw_image self.width - 20, 11, 0, 0, 8, 8
    else
      @lives_image.free unless @lives_image.nil?
      self.ctx.source = sprite.image
      @state.lives.to_i.times do |i|
        self.ctx.draw_image self.width - (8 + ((i + 1) * 12)), 11, 0, 0, 8, 8
      end
    end

    if @cache_score != @state.score
      @score_image.free unless @score_image.nil?
      @cache_score = @state.score

      self.ctx.font = "PressStart2P-Regular:8"
      self.ctx.color = 0xFFFFFF
      @score_image = self.ctx.create_text @cache_score.to_s.rjust(6, "0")
    end

    self.ctx.source = @score_image
    self.ctx.draw_image 12, 12
  end

  def playable_bounds
    {
      "left" => 8,
      "top" => 8,
      "right" => self.width - 9,
      "bottom" => self.height - 1,
    }
  end
end

class PlayerEntity < RGame::Core::Entity
  include RGame::Common::CollisionAspect
  include RGame::Common::SpriteAspect
  include RGame::Common::ControlsAspect
  include RGame::Common::PositionAspect
  include RGame::Common::MovementAspect
  include RGame::Common::RestrictAspect

  controls.left.speed = 64
  controls.right.speed = 64
  controls.wasd!
  controls.arrows!

  collision(NilClass).respond("slide")

  on :new do
    self.sprite = "player"
  end
end

class BlockEntity < RGame::Core::Entity
  include RGame::Common::SpriteAspect
  include RGame::Common::CollisionAspect
  include RGame::Common::PositionAspect
  include RGame::Common::DrawAspect

  include RGame::Core::Savable

  savable [ :x, :y, :sprite_tag ]

  collision.check_collisions = false

  attr_accessor :score

  on :new do
    self.sprite = "block"
    self.score = 100
  end

  on :ball_collision do
    self.broadcast :score, self.score
    PowerupEntity.generate(self.ctx).tap do |o|
      unless o.nil?
        o.x = self.x
        o.y = self.y
        self.parent.add(o)
      end
    end
    self.remove
  end
end

class HardBlockEntity < BlockEntity
  attr_accessor :hits

  savable [ :hits ]

  on :new do
    self.sprite_tag = "hard"
    self.hits = 2
    self.score = 200
  end

  around :ball_collision do |p|
    self.hits -= 1

    if self.hits <= 0
      p.call
    else
      self.sprite_tag = "hard_broken"
    end
  end

  def to_h
    super.merge({
      "hits" => self.hits,
    })
  end
end

class InvincibleBlockEntity < BlockEntity
  on :new do
    self.sprite_tag = "invincible"
  end

  before :ball_collision do |p|
    stop!
  end
end

class MovingBlockEntity < BlockEntity
  include RGame::Common::MovementAspect

  savable [ :x_speed, :y_speed ]

  on :new do
    self.sprite_tag = "red_moving"
    self.x_speed = 32
  end

  around :draw do |p|
    self.ctx.save do
      self.ctx.clip_bounds = self.parent.playable_bounds
      p.call
    end
  end

  after :interval do |dt|
    if self.x < (self.parent.playable_bounds["left"] - self.width)
      self.x = self.parent.playable_bounds["right"]
    elsif self.x > self.parent.playable_bounds["right"]
      self.x = self.parent.playable_bounds["left"] - self.width
    end
  end
end

class BallEntity < RGame::Core::Entity
  include RGame::Common::SpriteAspect
  include RGame::Common::PositionAspect
  include RGame::Common::MovementAspect
  include RGame::Common::CollisionAspect
  include RGame::Common::RestrictAspect
  include RGame::Common::TimerAspect

  attr_accessor :player

  DEFAULT_SPEED = 112
  STARTING_ANGLE = (3.0 * Math::PI / 4.0)
  ANGLE_CLAMP = [ (-7.0 * Math::PI / 8.0), (-1.0 * Math::PI / 8.0) ]
  ANGLE_RCLAMP = [ (-11.0 * Math::PI / 16.0), (-7.0 * Math::PI / 16.0) ]

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

  collision(NilClass).respond("deflect")

  collision(PlayerEntity).callback do |e|
    center_x = self.x + (self.width / 2)
    other_center_x = e.x + (e.width / 2)
    center_diff = (center_x - other_center_x) * (self.x_speed < 0 ? -1 : 1)
    new_angle = (center_diff * (Math::PI / 3.0) / 8.0) - (Math::PI / 2.0)
    self.angle = if new_angle.between?(*ANGLE_RCLAMP)
      ANGLE_RCLAMP.min_by { |e| (new_angle - e).abs }
    else
      new_angle.clamp(*ANGLE_CLAMP)
    end
  end

  collision(BlockEntity)
    .when { |_e| self.sprite_tag != "power_ball" }
    .emit(:ball_collision)
    .respond("deflect")

  collision(BlockEntity)
    .when { |_e| self.sprite_tag == "power_ball" }
    .emit(:ball_collision)
    .callback { |e, info| self.collision.deflect!(info) unless e.parent.nil? }

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

class PowerupEntity < RGame::Core::Entity
  FREQUENCIES = [
    [ "power_ball", 1 ],
    [ "1up", 1 ],
    [ "extra_ball", 1 ],
    [ "wide_paddle", 1 ],
    [ "slow_ball", 1 ],
    [ nil, 30 ],
  ]

  def self.generate context
    weight = FREQUENCIES.map { |e| e[1] }.sum
    table = FREQUENCIES.map do |e|
      [ e[0], e[1].to_f / weight.to_f]
    end.reduce([]) do |m,v|
      m + [ [ v[0], m.last&.last.to_f + v[1] ] ]
    end

    value = rand
    index = table.find_index { |e| e[1] >= value }.to_i
    unless table[index].first.nil?
      self.new(context).tap { |o| o.sprite_tag = table[index].first }
    end
  end

  include RGame::Common::CollisionAspect
  include RGame::Common::SpriteAspect
  include RGame::Common::PositionAspect
  include RGame::Common::MovementAspect

  on :new do
    self.sprite = "powerup"
    self.y_speed = 48
    self.sprite_tag = "power_ball"
  end

  collision(PlayerEntity) do
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
