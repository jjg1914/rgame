require "dungeon/core/aspect"

module Dungeon
  module Common
    module Control4WayAspect
      include Dungeon::Core::Aspect

      attr_reader :controls

      on :new do
        @controls = {
          "up" => {
            "keys" => [ "w", "k", "up" ],
            "speed" => 64,
          },
          "down" => {
            "keys" => [ "s", "j", "down" ],
            "speed" => 64,
          },
          "left" => {
            "keys" => [ "a", "h", "left" ],
            "speed" => 64,
          },
          "right" => {
            "keys" => [ "d", "l", "right" ],
            "speed" => 64,
          },
        }
      end

      on :keydown do |key|
        case key
        when *self.controls["up"]["keys"]
          self.y_speed -= self.controls["up"]["speed"]
          self.sprite_tag = self.controls["up"]["sprite_tag_start"]
        when *self.controls["left"]["keys"]
          self.x_speed -= self.controls["left"]["speed"]
          self.sprite_tag = self.controls["left"]["sprite_tag_start"]
        when *self.controls["down"]["keys"]
          self.y_speed += self.controls["down"]["speed"]
          self.sprite_tag = self.controls["down"]["sprite_tag_start"]
        when *self.controls["right"]["keys"]
          self.x_speed += self.controls["right"]["speed"]
          self.sprite_tag = self.controls["right"]["sprite_tag_start"]
        end
      end

      on :keyup do |key|
        case key
        when *self.controls["up"]["keys"]
          self.y_speed += self.controls["up"]["speed"]
          if y_speed == 0 and x_speed == 0
            self.sprite_tag = self.controls["up"]["sprite_tag_stop"]
          end
        when *self.controls["left"]["keys"]
          self.x_speed += self.controls["left"]["speed"]
          if y_speed == 0 and x_speed == 0
            self.sprite_tag = self.controls["left"]["sprite_tag_stop"]
          end
        when *self.controls["down"]["keys"]
          self.y_speed -= self.controls["down"]["speed"]
          if y_speed == 0 and x_speed == 0
            self.sprite_tag = self.controls["down"]["sprite_tag_stop"]
          end
        when *self.controls["right"]["keys"]
          self.x_speed -= self.controls["right"]["speed"]
          if y_speed == 0 and x_speed == 0
            self.sprite_tag = self.controls["right"]["sprite_tag_stop"]
          end
        end
      end
    end
  end
end
