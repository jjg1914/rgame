require "dungeon/aspect"

module Dungeon
  module ControlAspect
    include Dungeon::Aspect

    on :keydown do |key|
      case key
      when 'w', 'k', "up"
        self.y_speed -= 64
      when 'a', 'h', "left"
        self.x_speed -= 64
      when 's', 'j', "down"
        self.y_speed += 64
      when 'd', 'l', "right"
        self.x_speed += 64
      end
    end

    on :keyup do |key|
      case key
      when 'w', 'k', "up"
        self.y_speed += 64
      when 'a', 'h', "left"
        self.x_speed += 64
      when 's', 'j', "down"
        self.y_speed -= 64
      when 'd', 'l', "right"
        self.x_speed -= 64
      end
    end
  end
end
