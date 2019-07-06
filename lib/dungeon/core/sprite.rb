require "json"

module Dungeon
  module Core
    class Sprite
      attr_accessor :name
      attr_accessor :path
      attr_accessor :image

      attr_reader :width
      attr_reader :height

      class FrameData
        attr_reader :x
        attr_reader :y
        attr_reader :width
        attr_reader :height

        def initialize x, y, width, height
          @x = x
          @y = y
          @width = width
          @height = height
        end

        def to_a
          [ @x, @y, @width, @height ]
        end
      end

      class FrameTag
        attr_reader :frames
        attr_reader :keys

        def initialize frames, keys
          @frames = frames
          @keys = keys
        end

        def next_frame_key frame, key
          while @keys[frame] < key
            key -= @keys[frame]
            frame = (frame + 1) % @keys.size
          end

          [ frame, key ]
        end
      end

      def self.find_path_for name
        Env.sprite_path.split(File::PATH_SEPARATOR).map do |e|
          File.expand_path("%s.json" % name, e)
        end.find do |e|
          File.exist? e
        end
      end

      def self.load name
        path = find_path_for(name)
        raise "sprite not found %s" % name.inspect if path.nil?

        data = JSON.parse File.read path
        self.load_json(data).tap do |o|
          o.name = name
          o.path = path
        end
      end

      def self.load_json json
        frames = json["frames"].map do |e|
          FrameData.new e["frame"]["x"],
                        e["frame"]["y"],
                        e["frame"]["w"],
                        e["frame"]["h"]
        end

        tags = if json["meta"]["frameTags"].empty?
          range = self.range_for_direction("forward", 0, frames.size - 1)
          keys = range.map { |f| json["frames"][f]["duration"] }

          { "" => FrameTag.new(range, keys) }
        else
          json["meta"]["frameTags"].map do |e|
            range = self.range_for_direction(e["direction"], e["from"], e["to"])
            keys = range.map { |f| json["frames"][f]["duration"] }

            [ e["name"], FrameTag.new(range, keys) ]
          end.to_h
        end

        image = File.basename json["meta"]["image"], ".png"

        self.new(image, frames, tags)
      end

      def self.range_for_direction direction, from, to
        case
        when "forward"
          (from..to).to_a
        when "backward"
          (from..to).reverse.to_a
        when "pingpong"
          (from..to).to_a + ((from + 1)..(to - 1)).to_a
        else
          (from..to).to_a
        end
      end

      def initialize image, frames, tags
        @image = image
        @frames = frames
        @tags = tags

        @width = frames.max_by(&:width).width
        @height = frames.max_by(&:height).height
      end

      def next_frame_key tag, frame, key
        @tags.fetch(tag).next_frame_key frame, key
      end

      def at tag, frame
        @frames[@tags.fetch(tag).frames[frame]].to_a
      end

      def default_tag
        @default_tag ||= begin
          @tags.map do |k,v|
            [ k, v.frames.first ]
          end.reject do |k,v|
            v.nil?
          end.sort_by do |k,v|
            v
          end.first.first
        end
      end
    end
  end
end
