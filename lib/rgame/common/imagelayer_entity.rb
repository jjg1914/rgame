# frozen_string_literal: true

require "rgame/core/entity"
require "rgame/core/savable"

module RGame
  module Common
    class ImagelayerEntity < RGame::Core::Entity
      include RGame::Core::Savable

      attr_accessor :image

      savable :image

      on "draw" do
        self.ctx.renderer.source = self.image
        self.ctx.renderer.draw_image(0, 0)
      end

      def to_h
        super.merge({
          "image" => @image,
        })
      end
    end
  end
end
