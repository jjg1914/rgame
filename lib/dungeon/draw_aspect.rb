require "dungeon/aspect"
require "dungeon/assets"

module Dungeon
  module DrawAspect
    include Dungeon::Aspect

    attr_accessor :color
    attr_accessor :draw_fill
    attr_accessor :draw_stroke

    on :new do
      self.color = 0x0
      self.draw_fill = false
      self.draw_stroke = true
    end

    on :draw do |ctx|
      ctx.color = self.color
      ctx.draw_rect x.to_i, y.to_i, width.to_i, height.to_i if self.draw_stroke
      ctx.fill_rect x.to_i, y.to_i, width.to_i, height.to_i if self.draw_fill
    end
  end
end
