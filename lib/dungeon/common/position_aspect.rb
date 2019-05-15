require "dungeon/core/aspect"

module Dungeon
  module Common
    module PositionAspect 
      include Dungeon::Core::Aspect

      attr_accessor :x
      attr_accessor :y
      attr_accessor :width
      attr_accessor :height

      on :new do 
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
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
