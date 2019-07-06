require "dungeon/core/entity"
require "dungeon/core/tileset"
require "dungeon/core/savable"

module Dungeon
  module Common
    class TilelayerEntity < Dungeon::Core::Entity
      include Dungeon::Core::Savable

      attr_reader :tileset
      attr_reader :data
      attr_reader :width
      attr_reader :height

      savable [ :tileset, :data ]

      on :new do
        @data = []
      end

      on :draw do |ctx|
        get_var("ctx").draw_texture(@texture, 0, 0)
      end

      def to_h
        super.merge({
          "tileset" => @tileset.name,
          "data" => @data
        })
      end

      def tileset= value
        @tileset = unless value.is_a? Dungeon::Core::Tileset
          Dungeon::Core::Tileset.load value.to_s
        else
          value
        end

        _paint
      end

      def data= value
        @width = 0
        @data = value.to_a.map do |e|
          e.to_a.map { |f| f.to_i }.tap do |o|
            @width = [ @width, o.size ].max
          end
        end
        @height = @data.size

        _paint unless @tileset.nil?
      end

      private

      def _paint
        get_var("ctx").tap do |ctx|
          ctx.save do
            @texture = ctx.create_texture(@width * @tileset.tile_width,
                                          @height * @tileset.tile_height)
            ctx.target = @texture
     
            ctx.texture_blend_mode @texture, :blend
            ctx.color = 0x0
            ctx.alpha = 0x0
            ctx.clear

            @data.data.each_with_index do |e, i|
              e.each_with_index do |f, j|
                ctx.draw_sprite(@tileset.texture,
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
end
