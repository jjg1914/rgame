# frozen_string_literal: true

require "dungeon/core/entity"
require "dungeon/core/savable"

module Dungeon
  module Common
    class ImagelayerEntity < Dungeon::Core::Entity
      include Dungeon::Core::Savable

      attr_accessor :image

      savable :image

      on :draw do
        self.ctx.source = self.image
        self.ctx.draw_image(0, 0)
      end

      def to_h
        super.merge({
          "image" => @image,
        })
      end
    end
  end
end
