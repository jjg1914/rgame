# frozen_string_literal: true

require "rgame/core/collision"
require "rgame/core/aspect"

module RGame
  module Common
    module CollisionAspect
      include RGame::Core::Aspect

      class ClassMatcher
        def initialize klass
          @klass = klass
        end

        def call value
          value.is_a?(@klass)
        end
      end

      class PredicateMatcher
        def initialize method
          @method = method
        end

        def call value
          value.respond_to?(@method) and value.send(@method)
        end
      end

      class Component
        include Enumerable

        attr_accessor :check_collisions
        alias check_collisions? check_collisions

        def initialize
          @collisions = []
          @check_collisions = true
        end

        def add_collision matcher, response
          if matcher.is_a?(Class)
            @collisions << [ ClassMatcher.new(matcher), response ]
          elsif matcher.is_a?(String) or matcher.is_a?(Symbol)
            @collisions << [ PredicateMatcher.new(matcher), response ]
          elsif matcher.respond_to?("call")
            @collisions << [ matcher, response ]
          else
            raise ArgumentError matcher.inspect
          end
        end

        def each &blk
          if blk.nil?
            @collisions.each
          else
            @collisions.each(&blk)
          end
        end
      end

      module ClassMethods
        def collision *args, &blk
          return @collision if args.empty?

          args.each do |e|
            if e.is_a?(Hash)
              e.each do |k, v|
                @collision.add_collision(k, (v.nil? ? blk : v))
              end
            else
              @collision.add_collision(e, blk)
            end
          end
        end
      end

      class << self
        def included klass
          super
          klass.instance_eval do
            @collision = Component.new
            extend ClassMethods
          end
        end
      end

      on :pre_collision do |collision|
        collision.add(self)
      end

      around :post_collision do |p, collision|
        next p.call unless self.collision.check_collisions?

        @mtv = [ [ nil, 0 ], [ nil, 0 ] ]

        p.call

        collision.query(self).each do |e|
          mtv = RGame::Core::Collision.calculate_mtv(self, e)
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
        self.collision.select do |matcher, _response|
          matcher.call(e)
        end.each do |_matcher, response|
          if response.respond_to?("call")
            self.instance_exec(&response)
          elsif response.is_a?(String) or response.is_a?(Symbol)
            case response
            when "bump"
              @mtv[0] = [ @mtv[0], [ e, mtv[0] ] ].max_by { |f| f[1].abs }
              @mtv[1] = [ @mtv[1], [ e, mtv[1] ] ].max_by { |f| f[1].abs }
            else
              ArgumentError.new response.inspect
            end
          else
            ArgumentError.new response.inspect
          end
        end
      end

      on :bump do |_e, mtv|
        self.x += mtv[0]
        self.y += mtv[1]
      end

      def collision
        self.class.collision
      end
    end
  end
end
