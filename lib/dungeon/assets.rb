require "yaml"

require "dungeon/sprite"

module Dungeon
  module Assets
    extend self

    def init filename, renderer
      YAML.load_file(filename).each do |e|
        self[e["name"]] = case e["type"]
        when "sprite"
          Sprite.load renderer, e["path"]
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
