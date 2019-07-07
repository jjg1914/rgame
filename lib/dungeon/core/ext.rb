# frozen_string_literal: true

require "dungeon/core/dynamic_scope"

class Integer
  def self.from_rgb red, green, blue
    (red << 16) | (green << 8) | blue
  end

  def red_value
    # TODO ENDIAN
    (self & 0x00FF0000) >> 16
  end

  def green_value
    # TODO ENDIAN
    (self & 0x0000FF00) >> 8
  end

  def blue_value
    # TODO ENDIAN
    (self & 0x000000FF)
  end

  def alpha_value
    # TODO ENDIAN
    (self & 0xFF000000) >> 24
  end
end

module Kernel
  include Dungeon::Core::DynamicScope
end

class Object
  include Kernel
end
