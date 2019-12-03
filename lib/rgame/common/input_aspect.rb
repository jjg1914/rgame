# frozen_string_literal: true

require "forwardable"

require "rgame/core/aspect"
require "rgame/common/collision_aspect"

module RGame
  module Common
    module InputAspect
      include RGame::Core::Aspect

      class KeyMatcher < RGame::Common::CollisionAspect::BaseMatcher
        def initialize key
          super()
          @key = key
        end

        def call target, value, info
          super and @key == value
        end
      end

      class ClassComponent
        extend Forwardable
        def_delegators :@matchers, :[]

        def initialize
          @matchers = Hash.new { |h, k| h[k] = [] }
        end

        def initialize_clone source
          @matchers = Hash.new { |h, k| h[k] = [] }
          source.instance_variable_get(:@matchers).each do |k, v|
            @matchers[k] = v.map(&:clone)
          end
        end

        def add_matcher event, keys
          tmp = keys.flatten.map do |e|
            KeyMatcher.new(e).tap { |u| @matchers[event].push(u) }
          end

          RGame::Common::CollisionAspect::MatcherWrapper.new(tmp)
        end

        def keydown *args
          self.add_matcher("keydown", args)
        end

        def keyup *args
          self.add_matcher("keyup", args)
        end

        def keyrepeat *args
          self.add_matcher("keyrepeat", args)
        end
      end

      module ClassMethods
        attr_reader :input

        def inherited klass
          super
          klass.instance_exec(self) do |parent|
            @input = parent.input.clone
          end
        end
      end

      class << self
        def included klass
          super
          klass.instance_eval do
            @input = ClassComponent.new
            extend ClassMethods
          end
        end
      end

      %w[keydown keyup keyrepeat].each do |event|
        on(event) do |key, mod|
          self.class.input[event].select do |e|
            e.call(self, key, mod)
          end.each do |e|
            e.call_emit self, key
            e.callback self, key, mod
          end
        end
      end
    end
  end
end
