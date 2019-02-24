require "dungeon/aspect"

module Dungeon
  module PositionAspect 
    include Dungeon::Aspect

    attr_accessor :x
    attr_accessor :y

    on :new do 
      self.x = 0
      self.y = 0
    end
  end
end
