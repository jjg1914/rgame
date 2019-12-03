#!/usr/bin/env ruby

require "rgame/runtime"

require "matrix"

STAGE_WIDTH = 272
STAGE_HEIGHT = 288

SCALE_FACTOR = 2
WINDOW_WIDTH = STAGE_WIDTH * SCALE_FACTOR
WINDOW_HEIGHT = STAGE_HEIGHT * SCALE_FACTOR
VIEW_WIDTH = WINDOW_WIDTH / SCALE_FACTOR
VIEW_HEIGHT = WINDOW_HEIGHT / SCALE_FACTOR

class RGame::Common::RootEntity
  include RGame::Common::InputAspect

  window.title = "Arkanoid"
  window.size = [ WINDOW_WIDTH, WINDOW_HEIGHT ]

  context.scale = SCALE_FACTOR
  context.scale_quality = "nearest"

  input.keydown(%w[enter return])
    .when { self.size == 1 }
    .callback { |_| self.create(StageEntity) }

  on "start" do
    self.create(RGame::Common::CollectionEntity) do |o|
      o.create(RGame::Common::ImagelayerEntity) { |u| u.image = "stage-bg"}
      o.create(RGame::Common::ImagelayerEntity) { |u| u.image = "title"}
    end
  end

  on "gameover" do
    self.pop
  end
end

class StageEntity < RGame::Common::MapEntity
  STAGE_LIST = %w[stage1 stage2] 

  include RGame::Common::EditorAspect
  include RGame::Common::TimerAspect

  on "new" do
    @stage_index = 0
    @lives = 0
    @score = 0

    self.map = STAGE_LIST[@stage_index]
  end

  on "mapupdate" do
    @player = _create_player
    _create_ball
  end

  on "ballin" do
    _create_ball
  end

  on "ballout" do
    next unless _ball_count.zero?

    self.timer.set_timer(1000) do
      if @lives <= 0
        self.broadcast "gameover"
        self.remove
      else
        @player.clear_powerups
        @lives -= 1
        _create_ball
      end
    end
  end

  on "livesup" do |count|
    @lives += count
  end

  on "score" do |value|
    @score += value

    next unless _block_count.zero?
    self.timer.set_timer(1000) do
      @stage_index += 1

      if @stage_index >= STAGE_LIST.size
        self.parent.pop
      else
        self.map = STAGE_LIST[@stage_index]
      end
    end
  end

  after "draw" do
    self.ctx.renderer.font = "PressStart2P-Regular:8"
    self.ctx.renderer.color = 0xFFFFFF

    if @lives > 5
      self.ctx.renderer.draw_text @lives.to_s.rjust(2, " "), 12, 12

      self.ctx.renderer.source = "ball"
      self.ctx.renderer.draw_image self.width - 20, 11, 0, 0, 8, 8
    else
      self.ctx.renderer.source = "ball"
      @lives.to_i.times do |i|
        self.ctx.renderer.draw_image self.width - (8 + ((i + 1) * 12)), 11,
                                     0, 0, 8, 8
      end
    end

    self.ctx.renderer.draw_text @score.to_s.rjust(6, "0"), 12, 12
  end

  def playable_bounds
    {
      "left" => 8,
      "top" => 8,
      "right" => self.width - 9,
      "bottom" => self.height - 1,
    }
  end

  private

  def _create_player
    self.create(PlayerEntity) do |o|
      o.x = ((self.width - 8 - o.width) / 2) + 8
      o.y = self.height - 32

      o.x_restrict = (playable_bounds["left"]..playable_bounds["right"])
    end
  end

  def _create_ball
    self.create(BallEntity) do |o|
      o.player = @player
      o.x_restrict = (playable_bounds["left"]..playable_bounds["right"])
      o.y_restrict = (playable_bounds["top"]..)
    end
  end

  def _block_count
    self.children.count do |e|
      e.is_a?(BlockEntity) and not e.is_a?(InvincibleBlockEntity)
    end
  end

  def _ball_count
    self.children.count { |e| e.is_a?(BallEntity) }
  end
end

class PlayerEntity < RGame::Common::SimpleEntity
  include RGame::Common::ControlsAspect
  include RGame::Common::RestrictAspect
  include RGame::Common::TimerAspect

  controls.left.speed = 64
  controls.right.speed = 64
  controls.wasd!
  controls.arrows!

  collision(NilClass).respond("slide")

  sprite.name = "player"
  sprite.sprite_sized

  on "widen_player" do
    self.timer.set_timer(10000, { "tag" => "powerup_wide" }) do
      self.sprite.name = "player"
    end
    self.sprite.name = "player_wide"
  end

  def clear_powerups
    self.timer.clear
    self.sprite.name = "player"
  end
end

class BlockEntity < RGame::Common::SimpleEntity
  include RGame::Core::Savable
  include RGame::Common::RandomHelpers

  savable [ :x, :y, "sprite.tag" ]

  collision.check_collisions = false

  attr_accessor :score

  sprite.name = "block"
  sprite.sprite_sized

  on "new" do
    self.score = 100
  end

  on "ball_collision" do
    self.broadcast "score", self.score
    random_yield(0.20) do
      self.parent.create(PowerupEntity) do |o|
        o.x = self.x
        o.y = self.y
      end
    end
    self.remove
  end
end

class HardBlockEntity < BlockEntity
  attr_accessor :hits

  savable [ :hits ]

  sprite.tag = "hard"

  on "new" do
    self.hits = 2
    self.score = 200
  end

  around "ball_collision" do |p|
    self.hits -= 1

    if self.hits <= 0
      p.call
    elsif self.hits.finite?
      self.sprite.tag = "hard_broken"
    end
  end

  def to_h
    super.merge({
      "hits" => self.hits,
    })
  end
end

class InvincibleBlockEntity < HardBlockEntity
  sprite.tag = "invincible"

  on "new" do
    self.hits = Float::INFINITY
  end
end

class MovingBlockEntity < BlockEntity
  savable [ :x_speed, :y_speed ]

  sprite.tag = "red_moving"

  on "new" do
    self.x_speed = 32
  end

  around "draw" do |p|
    self.ctx.save do
      self.renderer.ctx.clip_bounds = self.parent.playable_bounds
      p.call
    end
  end

  after "interval" do |dt|
    if self.x < (self.parent.playable_bounds["left"] - self.width)
      self.x = self.parent.playable_bounds["right"]
    elsif self.x > self.parent.playable_bounds["right"]
      self.x = self.parent.playable_bounds["left"] - self.width
    end
  end
end

class BallEntity < RGame::Common::SimpleEntity
  include RGame::Common::RestrictAspect
  include RGame::Common::TimerAspect

  attr_accessor :player

  DEFAULT_SPEED = 112
  STARTING_ANGLE = (Math::PI / 4.0)
  ANGLE_CLAMP = [ (-7.0 * Math::PI / 8.0), (-1.0 * Math::PI / 8.0) ]
  ANGLE_RCLAMP = [ (-11.0 * Math::PI / 16.0), (-7.0 * Math::PI / 16.0) ]

  sprite.name = "ball"
  sprite.sprite_sized

  input.keydown(%w[space])
    .when_not { @started }
    .callback { |_| 
      @started = true

      self.speed = DEFAULT_SPEED
      self.angle = STARTING_ANGLE
    }

  on "interval" do
    unless @started
      unless @player.nil?
        self.x = @player.x + (3 * (@player.width / 4)) - (self.width / 2)
        self.y = @player.y - 12
      end
    else
      if self.y > STAGE_HEIGHT
        self.remove
        self.broadcast "ballout"
      end
    end
  end

  collision(NilClass)
    .respond("deflect")
    .callback { |_e| self.ctx.mixer.play_effect("ball_hit") }

  collision(PlayerEntity).callback do |e|
    self.ctx.mixer.play_effect("ball_player_hit")

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
    .when { |_e| self.sprite.tag != "power_ball" }
    .emit("ball_collision")
    .respond("deflect")
    .callback { |_e| self.ctx.mixer.play_effect("ball_block_hit") }

  collision(BlockEntity)
    .when { |_e| self.sprite.tag == "power_ball" }
    .emit("ball_collision")
    .callback do |e, info|
      self.collision.deflect!(info) unless e.parent.nil?
      self.ctx.mixer.play_effect("ball_block_hit")
    end

  on "slow" do
    self.timer.set_timer(5000, { "tag" => "powerup_slow" }) do
      self.speed = DEFAULT_SPEED
    end
    self.speed = 0.5 * DEFAULT_SPEED
  end

  on "power_ball" do
    self.timer.set_timer(5000, { "tag" => "powerup_powerball" }) do
      self.sprite.tag = "default"
    end
    self.sprite.tag = "power_ball"
  end
end

class PowerupEntity < RGame::Common::SimpleEntity
  include RGame::Common::RandomHelpers

  FREQUENCIES = [
    [ "power_ball", 1 ],
    [ "1up", 1 ],
    [ "extra_ball", 2 ],
    [ "wide_paddle", 2 ],
    [ "slow_ball", 2 ],
  ]

  sprite.name = "powerup"
  sprite.sprite_sized

  on "new" do
    self.y_speed = 48
    self.sprite.tag = random_weights_yield(FREQUENCIES)
  end

  collision(PlayerEntity) do
    case self.sprite.tag
    when "1up"
      self.broadcast "livesup", 1
    when "extra_ball"
      self.broadcast "ballin"
    when "wide_paddle"
      self.broadcast "widen_player"
    when "slow_ball"
      self.broadcast "slow"
    when "power_ball"
      self.broadcast "power_ball"
    end
    self.remove
  end
end
