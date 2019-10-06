# frozen_string_literal: true

require "forwardable"

require "rgame/core/collision"
require "rgame/core/aspect"

module RGame
  module Common
    module CollisionAspect
      include RGame::Core::Aspect

      class ClassComponent
        attr_accessor :check_collisions
        alias check_collisions? check_collisions

        def initialize
          @check_collisions = true
        end
      end

      class Component
        extend Forwardable
        def_delegators :@collisions, :each, :clear, :empty?, :each, :<<

        include Enumerable

        def initialize
          @collisions = []
        end
      end

      module ClassMethods
        attr_reader :collision

        def inherited klass
          super
          klass.instance_exec(self) do |parent|
            @collision = parent.collision.clone
          end
        end
      end

      class << self
        def included klass
          super
          klass.instance_eval do
            @collision = ClassComponent.new
            extend ClassMethods
          end
        end
      end

      attr_reader :collision

      on :new do
        @collision = RGame::Common::CollisionAspect::Component.new
      end

      on :collision_mark do |data|
        data.add(self)
      end

      around :collision_sweep do |p, data|
        next p.call unless self.class.collision.check_collisions?

        self.collision.clear

        p.call

        data.query(self).each do |e|
          info = RGame::Core::Collision::CollisionInfo.new(self, e)
          self.emit(:collision, e, info)
        end
      end

      on :collision do |e, info|
        if (self.respond_to?(:solid) and self.solid) and
           (e.respond_to?(:solid) and e.solid) or e.nil?
          self.collision << info
        end
      end

      on :collision_resolve do
        unless self.collision.empty?
          bump = self.collision.min_by(&:time)
          self.x, self.y = bump.position
          self.emit :bump, bump.other, bump
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
