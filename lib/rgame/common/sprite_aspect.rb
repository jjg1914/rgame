# frozen_string_literal: true

require "rgame/core/aspect"
require "rgame/core/sprite"

module RGame
  module Common
    module SpriteAspect
      module ClassMethods
        def self.extended klass
          klass.instance_eval do
            @sprite_sized = true
          end
        end

        def sprite_sized value = true
          @sprite_sized = value
        end

        def sprite_sized?
          @sprite_sized
        end

        def inherited klass
          super
          klass.instance_exec(self) do |parent|
            @sprite_sized = parent.sprite_sized?
          end
        end
      end

      include RGame::Core::Aspect

      attr_reader :sprite
      attr_reader :sprite_tag
      attr_accessor :sprite_frame
      attr_accessor :sprite_key
      attr_reader :sprite_translate

      def self.included klass
        super
        klass.instance_eval do
          extend ClassMethods
        end
      end

      def sprite= value
        @sprite = if value.is_a? RGame::Core::Sprite
          value
        else
          RGame::Core::Sprite.load value.to_s
        end
        self.sprite_tag = self.sprite.default_tag
        self.sprite_size! if self.class.sprite_sized?
      end

      def sprite_tag= value
        @sprite_tag = value.nil? ? self.sprite.default_tag : value
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
          value.take(2).map(&:to_i)
        end
      end

      def sprite_size!
        return if self.sprite.nil?

        self.width = self.sprite.width
        self.height = self.sprite.height
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

      on "draw" do
        at = self.sprite.at(self.sprite_tag, self.sprite_frame)

        self.ctx.renderer.source = self.sprite.image
        self.ctx.renderer.draw_image(x.to_i + self.sprite_translate[0],
                                     y.to_i + self.sprite_translate[1],
                                     *at)
      end

      def to_h
        super.merge({
          "sprite" => self.sprite.name,
          "sprite_tag" => self.sprite_tag,
          "sprite_frame" => self.sprite_frame,
          "sprite_key" => self.sprite_key,
          "sprite_translate" => self.sprite_translate,
        })
      end
    end
  end
end
