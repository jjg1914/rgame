# frozen_string_literal: true

require "rgame/core/aspect"

module RGame
  module Common
    module PathAspect
      include RGame::Core::Aspect

      attr_reader :path

      class Component
        attr_accessor :speed

        def initialize target
          @target = target
          @speed = 0
          @nodes = []
          @index = -1
        end

        def goto *args
          if args.size == 2
            self.goto_position(*args)
          elsif args.size == 1
            if args[0].is_a? Hash
              self.goto_bounds(*args)
            else
              raise ArgumentError.new "%s" % args[0].inspect
            end
          else
            raise ArgumentError.new "number of arguments: %i" % args.size
          end
        end

        def goto_position x, y
          @nodes << [ x.to_i, y.to_i, @speed ]
        end

        def goto_bounds bounds
          x = if bounds.key?("left")
            bounds["left"]
          elsif bounds.key?("right")
            @target.parent.width - @target.width - bounds["right"]
          elsif not @nodes.empty?
            @nodes.last[0]
          else
            @target.x
          end

          y = if bounds.key?("top")
            bounds["top"]
          elsif bounds.key?("bottom")
            @target.parent.height - @target.height - bounds["bottom"]
          elsif not @nodes.empty?
            @nodes.last[1]
          else
            @target.y
          end

          self.goto_position x, y
        end

        private

        def _step dt
          if _distance_to <= _step_size(dt)
            @target.x, @target.y = @nodes[@index].take(2) unless @index < 0
            @index += 1

            if @index == @nodes.size
              @target.send("path_end")
            else
              theta = _direction_to
              @target.x_speed = Math.cos(theta) * @nodes[@index][2]
              @target.y_speed = Math.sin(theta) * @nodes[@index][2]
            end
          end
        end

        def _direction_to
          dy = @nodes[@index][1] - @target.y
          dx = @nodes[@index][0] - @target.x
          Math.atan2(dy, dx)
        end

        def _distance_to
          if @index >= 0
            dx = @target.x - @nodes[@index][0]
            dy = @target.y - @nodes[@index][1]
            Math.sqrt((dx * dx) + (dy * dy))
          else
            0
          end
        end

        def _step_size dt
          speed = @target.speed
          if @target.speed == 0
            Float::INFINITY
          else
            [ speed * (dt / 1000.0), 1 ].max
          end
        end
      end

      def path
        if block_given?
          (@path = PathAspect::Component.new(self)).tap do |o|
            yield o
          end
        else
          @path
        end
      end

      on "interval" do |dt|
        @path&.send("_step", dt)
      end

      after "path_end" do
        @path = nil
      end
    end
  end
end
