module Dungeon
  module Core
    class Collision
      MAX_DEPTH = 8
      MAX_SIZE = 10

      class Node
        attr_reader :depth
        attr_reader :bounds
        attr_reader :mode
        attr_reader :children

        def initialize depth, bounds
          @depth = depth
          @bounds = bounds
          @mode = "leaf"
          @children = []
        end

        def split
          raise RuntimeError.new("node is branch") if branch?

          x_mid = @bounds["left"] + ((@bounds["right"] - @bounds["left"]) / 2)
          y_mid = @bounds["top"] + ((@bounds["bottom"] - @bounds["top"]) / 2)

          old_children = @children.dup
          @mode = "branch"
          @children.clear

          @children << Node.new(@depth + 1, {
            "left" => @bounds["left"],
            "top" => @bounds["top"],
            "right" => x_mid,
            "bottom" => y_mid,
          })

          @children << Node.new(@depth + 1, {
            "left" => x_mid + 1,
            "top" => @bounds["top"],
            "right" => @bounds["right"],
            "bottom" => y_mid,
          })

          @children << Node.new(@depth + 1, {
            "left" => @bounds["left"],
            "top" => y_mid + 1,
            "right" => x_mid,
            "bottom" => @bounds["bottom"],
          })

          @children << Node.new(@depth + 1, {
            "left" => x_mid + 1,
            "top" => y_mid + 1,
            "right" => @bounds["right"],
            "bottom" => @bounds["bottom"],
          })

          old_children.each do |e|
            @children.each { |f| f.add(e) if f.collides? e[0] }
          end
        end

        def unsplit
          raise RuntimeError.new("node is leaf") if leaf?

          old_children = @children.dup
          @mode = "leaf"
          @children.clear

          old_children.each do |e|
            e.unsplit unless e.leaf?
            @children.concat(e.children)
          end
        end

        def add data
          if collides? data[0]
            split if leaf? and @children.size == MAX_SIZE and @depth < MAX_DEPTH

            if leaf?
              @children << data
            else
              @children.each { |e| e.add(data) }
            end
          end
        end

        def query bounds, dest = {}
          if leaf?
            @children.select do |e|
              not dest.has_key?(e[1].id) and
                Collision.check_bounds(bounds, e[0])
            end.each do |e|
              dest[e[1].id] = e[1]
            end
          else
            @children.each { |e| e.query(bounds, dest) }
          end

          dest
        end

        def clear
          if leaf?
            @children.clear
          else
            if @children.all? { |e| e.empty? }
              unsplit
            else
              @children.each { |e| e.clear }
            end
          end
        end

        def collides? bounds
          Collision.check_bounds(@bounds, bounds)
        end

        def empty?
          if leaf?
            @children.empty?
          else
            @children.all? { |e| e.empty? }
          end
        end

        def leaf?
          self.mode == "leaf"
        end

        def branch?
          self.mode == "branch"
        end
      end

      def self.check a, b
        check_bounds(bounds_for(a), bounds_for(b))
      end

      def self.check_bounds a, b
        b["left"] <= a["right"] and a["left"] <= b["right"] and
          b["top"] <= a["bottom"] and a["top"] <= b["bottom"]
      end

      def self.bounds_for entity
        {
          "left" => entity.x,
          "top" => entity.y,
          "right" => entity.x + entity.width - 1,
          "bottom" => entity.y + entity.height - 1,
        }
      end

      def initialize width, height
        self.reset(width, height)
      end

      def add entity
        @root.add([
          Collision.bounds_for(entity),
          entity,
        ])
      end

      def query entity
        @root.query(Collision.bounds_for(entity)).tap do |o|
          o.delete entity.id
        end.values
      end

      def reset width, height
        @root = Node.new(0, {
          "left" => 0,
          "top" => 0,
          "right" => width - 1,
          "bottom" => height - 1,
        })
      end

      def clear
        @root.clear
      end
    end
  end
end
