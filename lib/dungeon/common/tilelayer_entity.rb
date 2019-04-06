require "dungeon/core/entity"

module Dungeon
  module Common
    class TilelayerEntity < Dungeon::Core::Entity
      on :new do |tilelayer, tileset|
        @tilelayer = tilelayer
        @tileset = tileset

        get_var("ctx").tap do |ctx|
          ctx.save do
            @texture = ctx.create_texture(@tilelayer.width * @tileset.tile_width,
                                          @tilelayer.height * @tileset.tile_height)
            ctx.target = @texture
     
            ctx.texture_blend_mode @texture, :blend
            ctx.color = 0x0
            ctx.alpha = 0x0
            ctx.clear

            @tilelayer.data.each_with_index do |e, i|
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

      on :draw do |ctx|
        get_var("ctx").draw_texture(@texture, 0, 0)
      end
    end
  end
end
