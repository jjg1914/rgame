# frozen_string_literal: true

require "rgame/core/map"
require "rgame/core/collision"
require "rgame/core/savable"
require "rgame/common/collection_entity"
require "rgame/common/tilelayer_entity"
require "rgame/common/imagelayer_entity"

module RGame
  module Common
    class MapEntity < CollectionEntity
      attr_reader :width
      attr_reader :height
      attr_accessor :background
      attr_reader :map

      on "new" do
        resize(*self.ctx.dimensions.zip(self.ctx.renderer.scale).map do |a, b|
          a / b
        end)
        @background = 0x0
      end

      after "interval" do
        self.emit "collision_mark", @collision
        self.emit "collision_sweep", @collision
        self.emit "collision_resolve", @collision
        @collision.clear
      end

      on "draw" do
        self.ctx.renderer.color = @background
        self.ctx.renderer.clear
      end

      def width= value
        resize value, @height
      end

      def height= value
        resize value, @height
      end

      def resize width, height
        @width = width
        @height = height
        @collision = RGame::Core::Collision.new(@width.to_i,
                                                @height.to_i)
      end

      def map= value
        self.remove_all

        @map = if value.is_a? RGame::Core::Map
          value
        else
          RGame::Core::Map.load value.to_s
        end

        resize @map.width, @map.height
        @background = @map.background

        @map.entities.flatten.reverse.each do |e|
          self.add_front RGame::Core::Savable.load(e, self.ctx)
        end

        self.emit "mapupdate"
      end
    end
  end
end
