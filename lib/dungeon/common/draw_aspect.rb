require "dungeon/core/aspect"
require "dungeon/core/assets"

module Dungeon
  module Common
    module DrawAspect
      include Dungeon::Core::Aspect

      COLOR_MAP = {
        "red" => 0xBB0000,
        "green" => 0x00BB00,
        "blue" => 0x0000BB,
        "yellow" => 0xBBBB00,
        "cyan" => 0x00BBBB,
        "magenta" => 0xBB00BB,
        "bright_red" => 0xFF0000,
        "bright_green" => 0x00FF00,
        "bright_blue" => 0x0000FF,
        "bright_yellow" => 0xFFFF00,
        "bright_cyan" => 0x00FFFF,
        "bright_magenta" => 0xFF00FF,
        "white" => 0xFFFFFF,
        "black" => 0x000000,
        "gray" => 0x888888,
        "grey" => 0x888888,
        "bright_gray" => 0xBBBBBB,
        "bright_grey" => 0xBBBBBB,
      }

      def self.parse_color value
        if value.nil?
          value
        elsif value.is_a? Numeric
          value.to_i
        else
          value = value.to_s.strip.downcase
          if COLOR_MAP.has_key? value
            COLOR_MAP[value]
          elsif value.start_with? "0x"
            value[2..-1].to_i 16
          elsif value.start_with? "0b"
            value[2..-1].to_i 2
          elsif value.start_with? "#"
            value[1..-1].to_i 16
          elsif value.start_with? "0"
            value[1..-1].to_i 8
          else
            value.to_i 10
          end
        end
      end

      attr_reader :fill_color
      attr_reader :stroke_color

      def fill_color= value
        @fill_color = DrawAspect.parse_color(value)
      end

      def stroke_color= value
        @stroke_color = DrawAspect.parse_color(value)
      end

      on :draw do 
        get_var("ctx").tap do |ctx|
          unless self.fill_color.nil?
            ctx.color = self.fill_color
            ctx.fill_rect x.to_i, y.to_i, width.to_i, height.to_i
          end

          unless self.stroke_color.nil?
            ctx.color = self.stroke_color
            ctx.draw_rect x.to_i, y.to_i, width.to_i, height.to_i
          end
        end
      end
    end
  end
end
