# frozen_string_literal: true

module RGame
  module Core
    class Collision
      MAX_DEPTH = 8
      MAX_SIZE = 10

      class CollisionInfo
        attr_reader :target
        attr_reader :other

        def self.calculate_mtv target, other
          self.calculate_mtv_bounds(target,
                                    RGame::Core::Collision.bounds_for(other))
        end

        def self.calculate_mtv_bounds target, other_bounds
          target_bounds = RGame::Core::Collision.bounds_for(target)

          [
            %w[left right],
            %w[top bottom],
          ].map do |args|
            _calculate_mtv_axis(target_bounds, other_bounds, *args)
          end
        end

        def self.calculate_sweep target, other
          self.calculate_sweep_bounds(target,
                                      RGame::Core::Collision.bounds_for(other))
        end

        def self.calculate_sweep_bounds target, other_bounds
          target_bounds = RGame::Core::Collision.bounds_for(target)

          x_change = _try_change(target, "x_change")
          y_change = _try_change(target, "y_change")
          x_entry, x_exit, x_sign = _calculate_entry_exit_axis(target_bounds,
                                                               other_bounds,
                                                               "left",
                                                               "right",
                                                               x_change)
          y_entry, y_exit, y_sign = _calculate_entry_exit_axis(target_bounds,
                                                               other_bounds,
                                                               "top",
                                                               "bottom",
                                                               y_change)

          entry_t = [ x_entry, y_entry ].max
          exit_t = [ x_exit, y_exit ].min

          if entry_t > exit_t or
             (x_entry.negative? and y_entry.negative?) or
             entry_t > 1
            [ 1, [ 0, 0 ] ]
          elsif x_entry > y_entry
            [ entry_t, [ x_sign, 0 ] ]
          else
            [ entry_t, [ 0, y_sign ] ]
          end
        end

        def initialize target, other
          @target = target
          @other = other
        end

        def mtv
          @mtv ||= begin
            CollisionInfo.calculate_mtv @target, @other
          end
        end

        def sweep
          @sweep ||= begin
            CollisionInfo.calculate_sweep @target, @other
          end
        end

        def normal
          @normal ||= self.sweep[1]
        end

        def time
          @time ||= self.sweep[0]
        end

        def position
          @position = begin
            [
              if @target.x_change.positive?
                (@target.x - (1 - self.time) * @target.x_change).floor
              else
                (@target.x - (1 - self.time) * @target.x_change).ceil
              end,
              if @target.y_change.positive?
                (@target.y - (1 - self.time) * @target.y_change).floor
              else
                (@target.y - (1 - self.time) * @target.y_change).ceil
              end,
            ]
          end
        end

        class << self
          private

          def _try_change target, method
            if target.respond_to?(method)
              target.send(method)
            else
              0
            end
          end

          def _calculate_mtv_axis target, other, min, max
            [
              other[min] - target[max],
              other[max] - target[min],
            ].min_by(&:abs)
          end

          def _calculate_entry_exit_axis target, other, min, max, change
            inv_entry, inv_exit = if change.positive?
              [
                other[min] - (target[max] - change),
                other[max] - (target[min] - change),
              ]
            else
              [
                other[max] - (target[min] - change),
                other[min] - (target[max] - change),
              ]
            end

            entry_t, exit_t = if change.zero?
              [ -Float::INFINITY, Float::INFINITY ]
            else
              [ inv_entry.to_f / change, inv_exit.to_f / change ]
            end

            [ entry_t, exit_t, -(change <=> 0) ]
          end
        end
      end

      class ReverseCollisionInfo < CollisionInfo
        def self.calculate_mtv_bounds target, other_bounds
          target_bounds = Collision.bounds_for(target)

          [
            %w[left right],
            %w[top bottom],
          ].map do |args|
            _calculate_mtv_reverse_axis(target_bounds, other_bounds, *args)
          end
        end

        def self.calculate_sweep_bounds target, other_bounds
          target_bounds = Collision.bounds_for(target)

          x_change = _try_change(target, "x_change")
          y_change = _try_change(target, "y_change")
          x_exit, x_sign = _calculate_exit_reverse_axis(target_bounds,
                                                        other_bounds,
                                                        "left",
                                                        "right",
                                                        x_change)
          y_exit, y_sign = _calculate_exit_reverse_axis(target_bounds,
                                                        other_bounds,
                                                        "top",
                                                        "bottom",
                                                        y_change)

          exit_t = [ x_exit, y_exit ].min

          if exit_t.negative? or exit_t >= 1
            [ 1, [ 0, 0 ] ]
          elsif x_exit < y_exit
            [ exit_t, [ x_sign, 0 ] ]
          else
            [ exit_t, [ 0, y_sign ] ]
          end
        end

        def other
          nil
        end

        def mtv
          @mtv ||= begin
            ReverseCollisionInfo.calculate_mtv_bounds @target, @other
          end
        end

        def sweep
          @sweep ||= begin
            ReverseCollisionInfo.calculate_sweep_bounds @target, @other
          end
        end

        class << self
          private

          def _calculate_mtv_reverse_axis target, other, min, max
            [
              other[min] - target[min],
              other[max] - target[max],
            ].min_by(&:abs)
          end

          def _calculate_exit_reverse_axis target, other, min, max, change
            inv_exit = if change.positive?
              other[max] - (target[max] - change)
            else
              other[min] - (target[min] - change)
            end

            exit_t = if change.zero?
              Float::INFINITY
            else
              inv_exit / change.to_f
            end

            [ exit_t, -(change <=> 0) ]
          end
        end
      end

      class Node
        attr_reader :depth
        attr_reader :bounds
        attr_reader :mode
        attr_reader :children

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

          RGame::Core::Collision::Node.divide_bounds(@bounds, 2, 2).tap do |o|
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
        def check target, other
          check_bounds(bounds_for(target), bounds_for(other))
        end

        def check_bounds target, other
          other["left"] <= target["right"] and
            target["left"] <= other["right"] and
            other["top"] <= target["bottom"] and
            target["top"] <= other["bottom"]
        end

        def check_point point, other
          check_point_bounds(point, bounds_for(other))
        end

        def check_point_bounds point, other
          other["left"] <= point[0] and point[0] <= other["right"] and
            other["top"] <= point[1] and point[1] <= other["bottom"]
        end

        def bounds_for entity
          {
            "left" => entity.x,
            "top" => entity.y,
            "right" => entity.x + entity.width - 1,
            "bottom" => entity.y + entity.height - 1,
          }
        end

        def deflect target, normal
          d = [ target.x_speed, target.y_speed ]
          dot = d.zip(normal).map { |a, b| a * b }.sum
          d.zip(normal).map { |a, b| a - (2 * dot * b) }
        end

        def slide target, normal
          normal = normal.reverse
          d = [ target.x_speed, target.y_speed ]
          dot = d.zip(normal).map { |a, b| a * b }.sum
          normal.map { |e| e * dot }
        end
      end
    end
  end
end
