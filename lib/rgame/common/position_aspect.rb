# frozen_string_literal: true

require "rgame/core/aspect"

module RGame
  module Common
    module PositionAspect
      include RGame::Core::Aspect

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
