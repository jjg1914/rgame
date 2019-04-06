require "yaml"

require "dungeon/core/sprite"
require "dungeon/core/tileset"
require "dungeon/core/map"

module Dungeon
  module Core
    module Assets
      extend self

      def init filename, renderer
        YAML.load_file(filename).each do |e|
          self[e["name"]] = case e["type"]
          when "sprite"
            Sprite.load renderer, e["path"]
          when "tileset"
            Tileset.load renderer, e["path"]
          when "map"
            Map.load e["path"]
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
