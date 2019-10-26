# frozen_string_literal: true

require "rgame/core/aspect"

module RGame
  module Common
    module ControlsAspect
      include RGame::Core::Aspect

      class Control
        attr_accessor :x_speed
        attr_accessor :y_speed
        attr_accessor :keys
        attr_accessor :tag

        def initialize speed_vec = [ 0, 0 ]
          self.speed_vec = speed_vec
          @x_speed = 0
          @y_speed = 0
          @keys = []
        end

        def speed= value
          @x_speed = speed_vec[0] * value
          @y_speed = speed_vec[1] * value
        end

        def speed
          [ @x_speed, @y_speed ].zip(speed_vec).map { |a, b| a * b }.sum
        end

        def inialize_clone source
          self.speed_vec = source.instance_variable_get(:@speed_vec)
          @x_speed = source.x_speed
          @y_speed = source.y_speed
          @keys = source.keys.clone
        end

        private

        attr_reader :speed_vec

        def speed_vec= value
          value = value.take(2)
          mag = Math.sqrt(value.map { |e| e * e }.sum)
          @speed_vec = if mag.zero?
            value
          else
            value.map { |e| e / mag }
          end
        end
      end

      class ClassComponent
        include Enumerable

        attr_reader :left
        attr_reader :right
        attr_reader :up
        attr_reader :down

        def initialize
          @left = Control.new [ -1, 0 ]
          @right = Control.new [ 1, 0 ]
          @up = Control.new [ 0, -1 ]
          @down = Control.new [ 0, 1 ]
        end

        def inialize_clone source
          @left = source.left.clone
          @right = source.right.clone
          @up = source.up.clone
          @down = source.down.clone
        end

        def to_h
          {
            "left" => self.left,
            "right" => self.right,
            "up" => self.up,
            "down" => self.down,
          }
        end

        def each &blk
          if blk.nil?
            self.to_h.each
          else
            self.to_h.each(&blk)
          end
        end

        def wasd!
          self.up.keys = (self.up.keys + %w[w]).uniq
          self.left.keys = (self.left.keys + %w[a]).uniq
          self.down.keys = (self.down.keys + %w[s]).uniq
          self.right.keys = (self.right.keys + %w[d]).uniq
        end

        def hjkl!
          self.left.keys = (self.left.keys + %w[h]).uniq
          self.up.keys = (self.up.keys + %w[j]).uniq
          self.down.keys = (self.down.keys + %w[k]).uniq
          self.right.keys = (self.right.keys + %w[l]).uniq
        end

        def arrows!
          self.left.keys = (self.left.keys + %w[left]).uniq
          self.right.keys = (self.right.keys + %w[right]).uniq
          self.up.keys = (self.up.keys + %w[up]).uniq
          self.down.keys = (self.down.keys + %w[down]).uniq
        end

        def speed= value
          self.h_speed = value
          self.v_speed = value
        end

        def h_speed= value
          self.left.speed = value
          self.right.speed = value
        end

        def v_speed= value
          self.up.speed = value
          self.down.speed = value
        end
      end

      class Component
        def initialize target
          @target = target
          @active = []
        end

        def activate_by_key key
          @target.class.controls.select do |_k, v|
            v.keys.include?(key) and not @active.include?(v)
          end.each do |_k, v|
            @active << v
          end
        end

        def deactivate_by_key key
          @target.class.controls.select do |_k, v|
            v.keys.include?(key) and @active.include?(v)
          end.each do |_k, v|
            @active.delete(v)
          end
        end

        def deactivate_by_normal normal
          @target.class.controls.select do |_k, v|
            dot = [ v.x_speed, v.y_speed ].zip(normal).map { |a, b| a * b }.sum
            not dot.zero? and @active.include?(v)
          end.each do |_k, v|
            @active.delete(v)
          end
        end
      end

      module ClassMethods
        attr_reader :controls

        def inherited klass
          super
          klass.instance_exec(self) do |parent|
            @controls = parent.controls.clone
          end
        end
      end

      class << self
        def included klass
          super
          klass.instance_eval do
            @controls = ClassComponent.new
            extend ClassMethods
          end
        end
      end

      attr_reader :controls

      on "new" do
        @controls = RGame::Common::ControlsAspect::Component.new self
      end

      on "keydown" do |key|
        self.controls.activate_by_key(key).each do |_k, v|
          self.x_speed += v.x_speed
          self.y_speed += v.y_speed
        end.map { |k, _v| k }.uniq.each do |e|
          self.emit "controls_start_%s" % e
        end
      end

      on "keyup" do |key|
        self.controls.deactivate_by_key(key).each do |_k, v|
          self.x_speed -= v.x_speed
          self.y_speed -= v.y_speed
        end.map { |k, _v| k }.uniq.each do |e|
          self.emit "controls_stop_%s" % e
        end
      end

      on "collision_bump" do |_other, info|
        self.controls.deactivate_by_normal(info.normal).each do |_k, v|
          self.x_speed -= v.x_speed if info.normal[0].zero?
          self.y_speed -= v.y_speed if info.normal[1].zero?
        end.map { |k, _v| k }.uniq.each do |e|
          self.emit "controls_stop_%s" % e
        end
      end
    end
  end
end
