# frozen_string_literal: true

require "rgame/core/aspect"
require "rgame/core/sprite"

module RGame
  module Common
    module SpriteAspect
      class ClassComponent
        attr_accessor :name
        attr_accessor :tag

        def initialize
          @sized = false
        end

        def sprite_sized value = true
          @sized = value
        end

        def sprite_sized?
          @sized
        end
      end

      class Component
        attr_reader :name
        attr_reader :tag
        attr_accessor :frame
        attr_accessor :key
        attr_reader :translate

        def initialize target
          @target = target
          self.name = @target.class.sprite.name
          self.tag = @target.class.sprite.tag
          self.frame = 0
          self.key = 0
          self.translate = 0
        end

        def name= value
          @name = if value.is_a? RGame::Core::Sprite
            value
          else
            RGame::Core::Sprite.load value.to_s
          end
          self.tag = self.name.default_tag
          self.sprite_size! if @target.class.sprite.sprite_sized?
        end

        def tag= value
          @tag = value.nil? ? self.name.default_tag : value
          self.frame = 0
          self.key = 0
        end

        def translate= value
          value = [ value, value ] unless value.is_a? Array
          @translate = if value.empty?
            [ 1, 1 ]
          elsif value.size == 1
            [ value[0].to_i, value[0].to_i ]
          else
            value.take(2).map(&:to_i)
          end
        end

        def sprite_size!
          return if self.name.nil?

          @target.width = self.name.width
          @target.height = self.name.height
        end
      end

      module ClassMethods
        def self.extended klass
          klass.instance_eval do
            @sprite = ClassComponent.new
          end
        end

        attr_reader :sprite

        def inherited klass
          super
          klass.instance_exec(self) do |parent|
            @sprite = parent.sprite.clone
          end
        end
      end

      include RGame::Core::Aspect

      attr_reader :sprite

      def self.included klass
        super
        klass.instance_eval do
          extend ClassMethods
        end
      end

      on "new" do
        @sprite = Component.new self
      end

      on "interval" do |dt|
        next if self.sprite.name.nil?

        key = self.sprite.key + dt

        tmp = self.sprite.name.next_frame_key(self.sprite.tag,
                                              self.sprite.frame,
                                              key)
        self.sprite.frame, self.sprite.key = tmp
      end

      on "draw" do
        at = self.sprite.name.at(self.sprite.tag, self.sprite.frame)

        self.ctx.renderer.source = self.sprite.name.image
        self.ctx.renderer.draw_image(x.to_i + self.sprite.translate[0],
                                     y.to_i + self.sprite.translate[1],
                                     *at)
      end

      def to_h
        super.merge({
          "sprite" => {
            "sprite" => self.sprite.name,
            "tag" => self.sprite.tag,
            "frame" => self.sprite.frame,
            "key" => self.sprite.key,
            "translate" => self.sprite.translate,
          },
        })
      end
    end
  end
end
