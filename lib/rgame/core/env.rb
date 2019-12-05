# frozen_string_literal: true

module RGame
  module Core
    module Env
      extend self

      def enable_software_mode
        not ENV["ENABLE_HEADLESS_MODE"].to_i.zero?
      end

      def enable_mmap_mode
        not ENV["ENABLE_MMAP_MODE"].to_i.zero?
      end

      def windows?
        not (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
      end

      def macos?
        not (/darwin/ =~ RUBY_PLATFORM).nil?
      end

      alias enable_software_mode? enable_software_mode
      alias enable_mmap_mode? enable_mmap_mode

      def mmap_file
        ENV.fetch("MMAP_FILE")
      end

      def mmap_file= value
        ENV.store("MMAP_FILE", value)
      end

      def font_path
        ENV.fetch("FONT_PATH", begin
          _expand_all_paths([
            File.join(assets_path, "fonts"),
            if self.windows?
              [ "C:\Windows\Fonts" ]
            elsif self.macos?
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

      def sound_path
        ENV.fetch("SOUND_PATH", begin
          [
            File.join(assets_path, "sounds"),
          ].join(File::PATH_SEPARATOR)
        end)
      end

      def sound_path= value
        ENV.store("SOUND_PATH", value)
      end

      def image_path
        ENV.fetch("IMAGE_PATH", begin
          [
            File.join(assets_path, "images"),
            self.sprite_path,
            self.tileset_path,
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
