require "dungeon/core/collision"
require "dungeon/core/aspect"

module Dungeon
  module Common
    module CollisionAspect 
      include Dungeon::Core::Aspect

      attr_accessor :solid

      on :pre_collision do 
        get_var("collision")&.add(self)
        @mtv = [ [ nil, 0 ], [ nil, 0 ] ]
      end

      on :post_collision do
        get_var("collision")&.query(self).each do |e|
          mtv = Dungeon::Core::Collision.calculate_mtv(self, e)
          self.emit(:collision, e, mtv)
        end

        if @mtv[0][0].equal? @mtv[1][0]
          unless @mtv[0][1] == 0 and @mtv[1][1] == 0
            self.emit(:bump, @mtv[0][0], [ @mtv[0][1], @mtv[1][1] ])
          end
        else
          if @mtv[0][1] != 0
            self.emit(:bump, @mtv[0][0], [ @mtv[0][1], 0 ])
          end

          if @mtv[1][1] != 0
            self.emit(:bump, @mtv[1][0], [ 0, @mtv[1][1] ])
          end
        end
      end

      on :collision do |e,mtv|
        @mtv[0] = [ @mtv[0], [ e, mtv[0] ] ].max_by { |f| f[1].abs }
        @mtv[1] = [ @mtv[1], [ e, mtv[1] ] ].max_by { |f| f[1].abs }
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
