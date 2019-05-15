require "dungeon/core/entity"
require "dungeon/core/savable"

module Dungeon
  module Common
    class ImagelayerEntity < Dungeon::Core::Entity
      include Dungeon::Core::Savable

      attr_reader :image

      savable :image

      on :draw do |ctx|
        get_var("ctx").draw_texture(@image.texture, 0, 0) unless @image.nil?
      end

      def image= value
        @image = unless value.is_a? Dungeon::Core::Image
          Dungeon::Core::Assets[value.to_s]
        else
          value
        end
      end

      def to_h
        super.merge({
          "image" => @image.name,
        })
      end
    end
  end
end
