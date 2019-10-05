# frozen_string_literal: true

require "rgame/core/collision"
require "rgame/core/aspect"

module RGame
  module Common
    module CollisionAspect
      include RGame::Core::Aspect

      around :post_collision do |p, collision|
        @collisions = []

        p.call

        collision.query(self).each do |e|
          info = RGame::Core::Collision::CollisionInfo.new(self, e)
          self.emit(:collision, e, info)
        end

        unless @collisions.empty?
          bump = @collisions.min_by(&:time)
          self.emit :bump, bump.other, bump
        end
      end

      on :collision do |e, info|
        if (self.respond_to?(:solid) and self.solid) and
           (e.respond_to?(:solid) and e.solid) or e.nil?
          @collisions << info
        end
      end

      on :bump do |_e, info|
        self.x, self.y = info.position
      end

      def to_h
        super.merge({
          "solid" => self.solid,
        })
      end
    end
  end
end
