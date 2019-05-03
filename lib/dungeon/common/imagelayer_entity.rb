module Dungeon
  module Common
    class ImagelayerEntity < Dungeon::Core::Entity
      on :new do |image|
        @image = unless image.is_a? Dungeon::Core::Image
          Dungeon::Core::Assets[image.to_s]
        else
          image
        end
      end

      on :draw do |ctx|
        get_var("ctx").draw_texture(@image.texture, 0, 0)
      end
    end
  end
end
