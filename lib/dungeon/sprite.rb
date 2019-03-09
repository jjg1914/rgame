require "json"

module Dungeon
  class Sprite
    attr_reader :texture

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

    def self.load renderer, filename
      data = JSON.parse(File.read filename)

      frames = data["frames"].map do |e|
        FrameData.new e["frame"]["x"],
                      e["frame"]["y"],
                      e["frame"]["w"],
                      e["frame"]["h"]
      end

      tags = data["meta"]["frameTags"].map do |e|
        range = self.range_for_direction(e["direction"], e["from"], e["to"])
        keys = range.map { |f| data["frames"][f]["duration"] }

        [ e["name"], FrameTag.new(range, keys) ]
      end.to_h

      surface = SDL2Image.IMG_Load data["meta"]["image"]
      texture = SDL2.SDL_CreateTextureFromSurface renderer, surface
      SDL2.SDL_FreeSurface surface

      self.new(texture, frames, tags)
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

    def initialize texture, frames, tags
      @texture = texture
      @frames = frames
      @tags = tags
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

    def close
      SDL2.SDL_DestroyTexture @texture
    end
  end
end
