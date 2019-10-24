# frozen_string_literal: true

module RGame
  module Core
    class SDLContext
      class FCFontCache < Hash
        def initialize renderer
          super() { |h, k| h[k] = _impl_load(*k) }
          @renderer = renderer

          @color_struct = SDL2::SDLColor.new
        end

        private

        def _impl_load value, color, alpha
          name, size = value.to_s.split(":", 2).map(&:strip)

          path = Env.font_path.split(":").map do |e|
            File.expand_path("%s.ttf" % name, e.strip)
          end.find do |e|
            File.exist?(e)
          end
          raise "font not found %s" % value.inspect if path.nil?

          @color_struct.assign_rgb_a color, alpha

          SDLFontCache.FC_CreateFont.tap do |o|
            SDLFontCache.FC_LoadFont(o, @renderer, path,
                                     size.to_i, @color_struct,
                                     SDL2TTF::TTF_STYLE_NORMAL)
          end
        end
      end
    end
  end
end
