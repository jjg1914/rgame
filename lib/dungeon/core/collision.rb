# frozen_string_literal: true

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
          raise "node is branch" if branch?

          old_children = @children.dup
          @mode = "branch"
          @children.clear

          Dungeon::Core::Collision.divide_bounds(@bounds, 2, 2).tap do |o|
            @children.concat(o.map do |e|
              Node.new(@depth + 1, e)
            end)
          end

          old_children.each do |e|
            @children.each { |f| f.add(e) }
          end
        end

        def unsplit
          raise "node is leaf" if leaf?

          old_children = @children.dup
          @mode = "leaf"
          @children.clear

          old_children.each do |e|
            e.unsplit unless e.leaf?
            @children.concat(e.children)
          end
        end

        def add data
          return unless collides? data[0]

          split if leaf? and @children.size >= MAX_SIZE and @depth < MAX_DEPTH

          if leaf?
            @children << data
          else
            @children.each { |e| e.add(data) }
          end

          true
        end

        def query bounds, dest = {}
          if leaf?
            @children.select do |e|
              not dest.key?(e[1].id) and Collision.check_bounds(bounds, e[0])
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
          elsif @children.all?(&:empty?)
            unsplit
          else
            @children.each(&:clear)
          end
        end

        def collides? bounds
          Collision.check_bounds(@bounds, bounds)
        end

        def empty?
          if leaf?
            @children.empty?
          else
            @children.all?(&:empty?)
          end
        end

        def leaf?
          self.mode == "leaf"
        end

        def branch?
          self.mode == "branch"
        end
      end

      def self.calculate_mtv target, other
        # left |-----| right      TARGET
        #     left |-----| right  OTHER
        #          |-|            MTV
        #      |---------|        MTV'

        target_bounds = self.bounds_for(target)
        other_bounds = self.bounds_for(other)

        [
          [ "left", "right", :x_change ],
          [ "top", "bottom", :y_change ],
        ].map do |args|
          _calculate_mtv_axis(target, target_bounds, other_bounds, *args)
        end
      end

      def self.check target, other
        check_bounds(bounds_for(target), bounds_for(other))
      end

      def self.check_bounds target, other
        other["left"] <= target["right"] and
          target["left"] <= other["right"] and
          other["top"] <= target["bottom"] and
          target["top"] <= other["bottom"]
      end

      def self.check_point point, other
        check_point_bounds(point, bounds_for(other))
      end

      def self.check_point_bounds point, other
        other["left"] <= point[0] and point[0] <= other["right"] and
          other["top"] <= point[1] and point[1] <= other["bottom"]
      end

      def self.bounds_for entity
        {
          "left" => entity.x,
          "top" => entity.y,
          "right" => entity.x + entity.width - 1,
          "bottom" => entity.y + entity.height - 1,
        }
      end

      def self.divide_bounds bounds, x_axis, y_axis
        x_step = (bounds["right"] - bounds["left"]).abs / 2
        y_step = (bounds["bottom"] - bounds["top"]).abs / 2

        y_axis.times.map do |j|
          top = bounds["top"] + (y_step * j) + j
          bottom = bounds["top"] + (y_step * (j + 1)) + j

          x_axis.times.map do |i|
            left = bounds["left"] + (x_step * i) + i
            right = bounds["left"] + (x_step * (i + 1)) + i

            {
              "left" => left,
              "right" => right,
              "top" => top,
              "bottom" => bottom,
            }
          end
        end.flatten
      end

      attr_reader :size
      attr_reader :root

      def initialize width, height
        self.reset(width, height)
      end

      def add entity
        @root.add([
          Collision.bounds_for(entity),
          entity,
        ]).tap { |o| @size += 1 if o }
      end

      def query entity
        @root.query(Collision.bounds_for(entity)).tap do |o|
          o.delete entity.id
        end.values
      end

      def reset width, height
        @size = 0
        @root = Node.new(0, {
          "left" => 0,
          "top" => 0,
          "right" => width - 1,
          "bottom" => height - 1,
        })
      end

      def clear
        @root.clear
        @size = 0
      end

      class << self
        private

        def _calculate_mtv_axis entity, target, other, min, max, change_method
          change = entity.then do |o|
            o.send(change_method) if o.respond_to? change_method
          end

          if not change.nil?
            if change.positive?
              _cutoff_mtv(other[min] - target[max], change)
            elsif change.negative?
              _cutoff_mtv(other[max] - target[min], change)
            else
              0
            end
          else
            [
              other[min] - target[max],
              other[max] - target[min],
            ].min_by(&:abs)
          end
        end

        def _cutoff_mtv value, cutoff
          if value.abs <= cutoff.abs
            value
          else
            0
          end
        end
      end
    end
  end
end
