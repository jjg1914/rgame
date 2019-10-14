# frozen_string_literal: true

require "rgame/core/aspect"

module RGame
  module Common
    module MovementAspect
      include RGame::Core::Aspect

      attr_accessor :x_subpixel
      attr_accessor :y_subpixel
      attr_accessor :x_speed
      attr_accessor :y_speed
      attr_accessor :x_change
      attr_accessor :y_change

      on "new" do
        self.x_subpixel = 0
        self.y_subpixel = 0
        self.x_speed = 0
        self.y_speed = 0
        self.x_change = 0
        self.y_change = 0
      end

      on "interval" do |dt|
        self.x_subpixel += x_speed * dt
        self.y_subpixel += y_speed * dt

        self.x_change = if x_subpixel >= 1000 or x_subpixel.negative?
          d, r = x_subpixel.divmod 1000
          self.x += d
          self.x_subpixel = r
          d
        end.to_i

        self.y_change = if y_subpixel >= 1000 or y_subpixel.negative?
          d, r = y_subpixel.divmod 1000
          self.y += d
          self.y_subpixel = r
          d
        end.to_i
      end

      def angle
        Math.atan2(self.y_speed, self.x_speed)
      end

      def angle= value
        tmp = self.speed
        self.x_speed = tmp * Math.cos(value)
        self.y_speed = tmp * Math.sin(value)
      end

      def speed
        Math.sqrt((self.x_speed**2) + (self.y_speed**2))
      end

      def speed= value
        tmp = self.angle
        self.x_speed = value * Math.cos(tmp)
        self.y_speed = value * Math.sin(tmp)
      end

      def to_h
        super.merge({
          "x_speed" => self.x_speed,
          "y_speed" => self.y_speed,
          "x_subpixel" => self.x_subpixel,
          "y_subpixel" => self.y_subpixel,
          "x_change" => self.x_change,
          "y_change" => self.y_change,
        })
      end
    end
  end
end
