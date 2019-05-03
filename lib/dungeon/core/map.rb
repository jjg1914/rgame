require "json"

module Dungeon
  module Core
    class Map
      attr_reader :width
      attr_reader :height
      attr_reader :tile_width
      attr_reader :tile_height

      attr_reader :layers
      attr_reader :tileset

      attr_reader :background

      class Imagelayer
        attr_reader :image

        def self.from_json json
          ext_name = File.extname json["image"]
          self.new File.basename json["image"], ext_name
        end

        def initialize image
          @image = image
        end
      end

      class Objectgroup
        attr_reader :data

        def self.from_json json
          self.new(json["objects"].map do |e|
            e.dup.keep_if do |k,v|
              %w[type x y width height].include? k
            end.merge(Hash[*(e.fetch("properties", {}).map do |k,v|
              case e.fetch("propertytypes", {})[k].to_s.strip.downcase
              when "int"
                [ k, v.to_i ]
              when "float"
                [ k, v.to_f ]
              when "bool"
                [ k, !!v.to_i ]
              else
                [ k, v.to_s ]
              end
            end.flatten(1))])
          end)
        end

        def self.load_entity_const name
          begin
            const_get(name.split("::").map do |e|
              e.split("_").map do |f|
                f.downcase.tap { |o| o[0] = o[0].upcase } + "Entity"
              end.join
            end.join("::"))
          rescue NameError
            STDERR.puts "no entity type %s" % name
          end
        end

        def self.load_entity data
          data = data.dup
          const = load_entity_const(data.delete("type"))
          unless const.nil?
            const.new.tap do |o|
              data.each do |k,v|
                if o.respond_to?("%s=" % k)
                  o.send("%s=" % k, v)
                else
                  STDERR.puts "%s has no writer %s" % [ o, k ]
                end
              end
            end
          end
        end

        def initialize data
          @data = data
        end

        def load_entities
          @data.map { |e| self.class.load_entity(e) }.reject { |e| e.nil? }
        end
      end

      class Tilelayer
        attr_reader :data
        attr_reader :width
        attr_reader :height

        def self.from_json json
          self.new(json["height"].times.map do |j|
            json["width"].times.map do |i|
              offset = (j * json["width"]) + i
              json["data"][offset] - 1
            end
          end, json["width"], json["height"])
        end
    
        def initialize data, width, height
          @data = data
          @width = width
          @height = height
        end
      end

      def self.load filename
        data = JSON.parse File.read filename

        layers = data["layers"].map do |e|
          case e["type"]
          when "imagelayer"
            Imagelayer
          when "tilelayer"
            Tilelayer
          when "objectgroup"
            Objectgroup
          end.from_json(e)
        end

        tileset = unless data["tilesets"].empty?
          tile.basename(data["tilesets"].first["source"], ".json")
        end

        background = if /#([[:xdigit:]]{6})/ =~ data["backgroundcolor"]
          $~[1].to_i(16)
        else
          0xAAAAAA
        end

        self.new(data["width"], data["height"],
                 data["tilewidth"], data["tileheight"],
                 layers, tileset, background)
      end

      def initialize width, height, tile_width, tile_height, layers, tileset, background
        @width = width
        @height = height
        @tile_width = tile_width
        @tile_height = tile_height
        @layers = layers
        @tileset = tileset
        @background = background
      end
    end
  end
end
