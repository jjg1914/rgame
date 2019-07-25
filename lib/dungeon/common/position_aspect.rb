require "dungeon/core/aspect"

module Dungeon
  module Common
    module PositionAspect 
      module ClassMethods
        def set_collisions value
          @collisions = !!value
        end

        def collisions?
          @collisions
        end
      end

      def self.included klass
        super
        klass.instance_eval do
          extend Dungeon::Common::PositionAspect::ClassMethods
          set_collisions true
        end
      end

      include Dungeon::Core::Aspect

      attr_accessor :x
      attr_accessor :y
      attr_accessor :width
      attr_accessor :height

      attr_accessor :solid

      on :new do 
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
        self.solid = true
      end

      on :pre_collision do |collision|
        collision.add(self)
      end

      def to_h
        super.merge({
          "x" => self.x,
          "y" => self.y,
          "width" => self.width,
          "height" => self.height,
        })
      end
    end
  end
end
