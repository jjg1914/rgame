require "dungeon/core/aspect"

module Dungeon
  module Common
    module ControlAspect
      include Dungeon::Core::Aspect

      on :keydown do |key|
        case key
        when 'w', 'k', "up"
          self.y_speed -= 64
          self.sprite_tag = "walk-up"
        when 'a', 'h', "left"
          self.x_speed -= 64
          self.sprite_tag = "walk-left"
        when 's', 'j', "down"
          self.y_speed += 64
          self.sprite_tag = "walk-down"
        when 'd', 'l', "right"
          self.x_speed += 64
          self.sprite_tag = "walk-right"
        end
      end

      on :keyup do |key|
        case key
        when 'w', 'k', "up"
          self.y_speed += 64
          self.sprite_tag = "stand-up" if y_speed == 0 and x_speed == 0
        when 'a', 'h', "left"
          self.x_speed += 64
          self.sprite_tag = "stand-left" if y_speed == 0 and x_speed == 0
        when 's', 'j', "down"
          self.y_speed -= 64
          self.sprite_tag = "stand-down" if y_speed == 0 and x_speed == 0
        when 'd', 'l', "right"
          self.x_speed -= 64
          self.sprite_tag = "stand-right" if y_speed == 0 and x_speed == 0
        end
      end
    end
  end
end
