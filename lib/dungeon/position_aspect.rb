require "dungeon/aspect"

module Dungeon
  module PositionAspect 
    include Dungeon::Aspect

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
  end
end
