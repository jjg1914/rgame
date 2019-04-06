require "dungeon/core/aspect"
require "dungeon/core/sprite"
require "dungeon/core/assets"

module Dungeon
  module Common
    module SpriteAspect
      include Dungeon::Core::Aspect

      attr_accessor :sprite
      attr_accessor :sprite_tag
      attr_accessor :sprite_frame
      attr_accessor :sprite_key
      attr_accessor :sprite_translate

      def sprite= value
        if value.is_a? Dungeon::Core::Sprite
          @sprite = value
        else
          @sprite = Dungeon::Core::Assets[value.to_s]
        end
        self.sprite_tag = self.sprite.default_tag
      end

      def sprite_tag= value
        @sprite_tag = value
        self.sprite_frame = 0
        self.sprite_key = 0
      end

      def sprite_translate= value
        value = [ value, value ] unless value.is_a? Array
        @sprite_translate = if value.empty?
          [ 1, 1 ]
        elsif value.size == 1
          [ value[0].to_i, value[0].to_i ]
        else
          value.take(2).map { |e| e.to_i }
        end
      end

      on :new do
        self.sprite_frame = 0
        self.sprite_key = 0
        self.sprite_translate = 0
      end

      on :interval do |dt|
        unless self.sprite.nil?
          key = self.sprite_key + dt

          tmp = self.sprite.next_frame_key(self.sprite_tag,
                                           self.sprite_frame,
                                           key)
          self.sprite_frame, self.sprite_key = tmp
        end
      end

      on :draw do
        get_var("ctx").draw_sprite(self.sprite.texture,  
                                   x.to_i + self.sprite_translate[0],
                                   y.to_i + self.sprite_translate[1],
                                   *self.sprite.at(self.sprite_tag, self.sprite_frame))
      end
    end
  end
end
