# frozen_string_literal: true

require "rgame/core/entity"
require "rgame/core/tileset"
require "rgame/core/savable"

module RGame
  module Common
    class TilelayerEntity < RGame::Core::Entity
      include RGame::Core::Savable

      attr_reader :tileset
      attr_reader :data
      attr_reader :width
      attr_reader :height

      savable %i[tileset data]

      on "new" do
        @data = []
      end

      on "draw" do
        self.ctx.draw_texture(@texture, 0, 0)
      end

      def to_h
        super.merge({
          "tileset" => @tileset.name,
          "data" => @data,
        })
      end

      def tileset= value
        @tileset = if value.is_a? RGame::Core::Tileset
          value
        else
          RGame::Core::Tileset.load value.to_s
        end

        _paint
      end

      def data= value
        @width = 0
        @data = value.to_a.map do |e|
          e.to_a.map(&:to_i).tap do |o|
            @width = [ @width, o.size ].max
          end
        end
        @height = @data.size

        _paint unless @tileset.nil?
      end

      private

      def _paint
        self.ctx.save do
          @texture = ctx.create_texture(@width * @tileset.tile_width,
                                        @height * @tileset.tile_height)
          self.ctx.target = @texture

          self.ctx.texture_blend_mode @texture, :blend
          self.ctx.color = 0x0
          self.ctx.alpha = 0x0
          self.ctx.clear

          @data.data.each_with_index do |e, i|
            e.each_with_index do |f, j|
              self.ctx.draw_sprite(@tileset.texture,
                                   j * @tileset.tile_width,
                                   i * @tileset.tile_height,
                                   *@tileset.at(f))
            end
          end
        end
      end
    end
  end
end
