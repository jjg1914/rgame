# frozen_string_literal: true

module Dungeon
  module Core
    module Env
      extend self

      def font_path
        ENV.fetch("FONT_PATH", begin
          _expand_all_paths([
            File.join(assets_path, "fonts"),
            if not (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
              [ "C:\Windows\Fonts" ]
            elsif not (/darwin/ =~ RUBY_PLATFORM).nil?
              [ "~/Library/Fonts", "/Library/Fonts" ]
            else
              [ "~/.fonts", "/usr/share/fonts" ]
            end,
          ])
        end)
      end

      def font_path= value
        ENV.store("FONT_PATH", value)
      end

      def image_path
        ENV.fetch("IMAGE_PATH", begin
          [
            File.join(assets_path, "images"),
            File.join(assets_path, "sprites"),
            File.join(assets_path, "tilesets"),
          ].join(File::PATH_SEPARATOR)
        end)
      end

      def image_path= value
        ENV.store("IMAGE_PATH", value)
      end

      def sprite_path
        ENV.fetch("SPRITE_PATH", begin
          File.join(assets_path, "sprites")
        end)
      end

      def sprite_path= value
        ENV.store("SPRITE_PATH", value)
      end

      def tileset_path
        ENV.fetch("TILESET_PATH", begin
          File.join(assets_path, "tilesets")
        end)
      end

      def tileset_path= value
        ENV.store("TILESET_PATH", value)
      end

      def map_path
        ENV.fetch("MAP_PATH", begin
          File.join(assets_path, "maps")
        end)
      end

      def map_path= value
        ENV.store("MAP_PATH", value)
      end

      def assets_path
        File.expand_path(ENV.fetch("ASSETS_PATH", begin
          File.join(File.dirname($0), "assets")
        end))
      end

      def assets_path= value
        ENV.store("ASSETS_PATH", value)
      end

      private

      def _expand_all_paths paths
        paths.flatten.map do |e|
          e.split(File::PATH_SEPARATOR).map do |f|
            File.expand_path(f.strip)
          end
        end.flatten.join(File::PATH_SEPARATOR)
      end
    end
  end
end
