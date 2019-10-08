# frozen_string_literal: true

require "forwardable"

require "rgame/core/collision"
require "rgame/core/aspect"

module RGame
  module Common
    module CollisionAspect
      include RGame::Core::Aspect

      class BaseMatcher
        attr_reader :response

        def initialize
          @when = []
          @emit = []
        end

        def respond value
          @response = value
        end

        def callback *args, &block
          if block.nil?
            target, *rest = *args
            target.instance_exec(*rest, &@callback) unless @callback.nil?
          else
            @callback = if args.empty?
              block
            else
              proc { |*extra| block.call(*(extra + args)) }
            end
          end
        end

        def when &block
          @when << block
        end

        def emit *args
          @emit << args
        end

        def call_emit target, value
          return if value.nil?
          @emit.each do |e|
            value.emit(e.first, target, *e.drop(1))
          end
        end

        def call target, value, info
          @when.empty? or @when.all? do |e|
            target.instance_exec(value, info, &e)
          end
        end
      end

      class ClassMatcher < BaseMatcher
        def initialize klass
          super()
          @klass = klass
        end

        def call target, value, info
          super and value.is_a?(@klass)
        end
      end

      class MatcherWrapper
        def initialize matchers
          @matchers = matchers
        end

        def respond value
          @matchers.each { |e| e.respond(value) }
          self
        end

        def callback *args, &block
          @matchers.each { |e| e.callback(*args, &block) }
          self
        end

        def emit *args
          @matchers.each { |e| e.emit(*args) }
          self
        end

        def when &block
          @matchers.each { |e| e.when(&block) }
          self
        end
      end

      class ClassComponent
        extend Forwardable
        def_delegators :@matchers, :each

        include Enumerable

        attr_accessor :check_collisions
        alias check_collisions? check_collisions

        def initialize
          @check_collisions = true
          @matchers = []
        end

        def add_matcher arg
          if arg.is_a?(Class)
            ClassMatcher.new(arg)
          else
            raise ArgumentError.new(arg.inspect)
          end.tap do |o|
            @matchers.push(o)
          end
        end
      end

      class Component
        extend Forwardable
        def_delegators :@collisions, :each, :clear, :empty?, :<<

        include Enumerable

        def initialize target
          @target = target
          @collisions = []
        end

        def deflect! info
          @target.x, @target.y = info.position
          @target.x_speed, @target.y_speed =
            RGame::Core::Collision.deflect @target, info.normal
        end

        def slide! info
          @target.x, @target.y = info.position
          @target.x_speed, @target.y_speed =
            RGame::Core::Collision.slide @target, info.normal
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

        def collision *args, &block
          return @collision if args.empty?

          MatcherWrapper.new(args.map do |e|
            @collision.add_matcher e
          end).tap { |o| o.callback(&block) unless block.nil? }
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
        @collision = RGame::Common::CollisionAspect::Component.new self
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
        self.class.collision.select { |f| f.call(self, e, info) }.each do |f|
          if f.response.nil?
            f.call_emit self, e
            f.callback self, e, info
          else
            self.collision << [ f, e, info ]
          end
        end
      end

      on :collision_resolve do
        unless self.collision.empty?
          bump = self.collision.min_by { |e| e[2].time }

          case bump[0].response
          when "deflect"
            self.collision.deflect! bump[2]
          when "slide"
            self.collision.slide! bump[2]
          else
            raise "unknown response %s" % bump[0].response
          end

          bump[0].call_emit self, bump[1]
          bump[0].callback self, bump[1], bump[2]
          self.emit :collision_bump, bump[1], bump[2]
        end
      end
    end
  end
end
