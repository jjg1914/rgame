require "dungeon/aspect"

module Dungeon
  module DrawAspect
    include Dungeon::Aspect

    on :draw do |ctx|
      ctx.color = 0x0000FF
      ctx.fill_rect x.to_i, y.to_i, 32, 32
    end
  end
end
