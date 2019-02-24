require "dungeon/aspect"

module Dungeon
  module MovementAspect
    include Dungeon::Aspect

    attr_accessor :x_subpixel
    attr_accessor :y_subpixel
    attr_accessor :x_speed
    attr_accessor :y_speed

    on :new do 
      self.x_subpixel = 0
      self.y_subpixel = 0
      self.x_speed = 0
      self.y_speed = 0
    end

    on :interval do |dt|
      self.x_subpixel += x_speed * dt
      self.y_subpixel += y_speed * dt

      if x_subpixel >= 1000 or x_subpixel < 0
        d, r = x_subpixel.divmod 1000
        self.x += d
        self.x_subpixel = r
      end

      if y_subpixel >= 1000 or y_subpixel < 0
        d, r = y_subpixel.divmod 1000
        self.y += d
        self.y_subpixel = r
      end
    end
  end
end
