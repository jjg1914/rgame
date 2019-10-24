# frozen_string_literal: true

module RGame
  module Core
    class SDLContext
      class TTFFontCache < Hash
        def initialize
          super() { |h, k| h[k] = _impl_load(k) }
        end

        private

        def _impl_load value
          name, size = value.to_s.split(":", 2).map(&:strip)

          path = Env.font_path.split(":").map do |e|
            File.expand_path("%s.ttf" % name, e.strip)
          end.find do |e|
            File.exist?(e)
          end
          raise "font not found %s" % value.inspect if path.nil?

          SDL2TTF.TTF_OpenFont path, size.to_i
        end
      end
    end
  end
end
