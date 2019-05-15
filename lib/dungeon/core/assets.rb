require "yaml"

require "dungeon/core/image"
require "dungeon/core/sprite"
require "dungeon/core/tileset"
require "dungeon/core/map"

module Dungeon
  module Core
    module Assets
      extend self

      def init filename, renderer
        base_dir = File.dirname File.expand_path filename

        YAML.load_file(filename).each do |e|
          path = File.expand_path e["path"], base_dir

          self[e["name"]] = case e["type"]
          when "sprite"
            Sprite.load renderer, path
          when "tileset"
            Tileset.load renderer, path
          when "png"
            Image.load renderer, path
          when "map"
            Map.load_file path
          end
        end
      end

      def [] asset
        self.load(asset)
      end

      def []= asset, value
        self.store(asset, value)
      end

      def load asset
        self.data.fetch(asset)
      end

      def store asset, value
        self.data.store(asset, value)
      end

      def data
        (@data ||= {})
      end
    end
  end
end
