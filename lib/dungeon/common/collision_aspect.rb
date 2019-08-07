# frozen_string_literal: true

require "dungeon/core/collision"
require "dungeon/core/aspect"

module Dungeon
  module Common
    module CollisionAspect
      include Dungeon::Core::Aspect

      around :post_collision do |p, collision|
        @mtv = [ [ nil, 0 ], [ nil, 0 ] ]

        p.call

        collision.query(self).each do |e|
          mtv = Dungeon::Core::Collision.calculate_mtv(self, e)
          self.emit(:collision, e, mtv)
        end

        if @mtv[0][0].equal? @mtv[1][0]
          unless @mtv[0][1].zero? and @mtv[1][1].zero?
            self.emit(:bump, @mtv[0][0], [ @mtv[0][1], @mtv[1][1] ])
          end
        else
          unless @mtv[0][1].zero?
            self.emit(:bump, @mtv[0][0], [ @mtv[0][1], 0 ])
          end

          unless @mtv[1][1].zero?
            self.emit(:bump, @mtv[1][0], [ 0, @mtv[1][1] ])
          end
        end
      end

      on :collision do |e, mtv|
        if (self.respond_to?(:solid) and self.solid) and
           (e.respond_to?(:solid) and e.solid) or e.nil?
          @mtv[0] = [ @mtv[0], [ e, mtv[0] ] ].max_by { |f| f[1].abs }
          @mtv[1] = [ @mtv[1], [ e, mtv[1] ] ].max_by { |f| f[1].abs }
        end
      end

      on :bump do |e, mtv|
        if self.solid and (e.nil? or e.solid)
          self.x += mtv[0]
          self.y += mtv[1]
        end
      end

      def to_h
        super.merge({
          "solid" => self.solid,
        })
      end
    end
  end
end
