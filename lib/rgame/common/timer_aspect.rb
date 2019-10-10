# frozen_string_literal: true

require "rgame/core/collision"
require "rgame/core/aspect"

module RGame
  module Common
    module TimerAspect
      include RGame::Core::Aspect

      attr_reader :timer

      class Component
        attr_reader :timers

        def initialize target
          @target = target
          @timers = []
          @tags = {}
        end

        def set_timer millis, options = {}, &block
          if options&.key? "tag"
            self.clear_tag options["tag"]
            @tags[options["tag"]] = @timers.size
          end
          @timers << [ millis, block ]
          block
        end

        def poll_timer timer
          index = @timers.find_index { |o| o.last == timer }
          @timers[index].first unless index.nil?
        end

        def poll_tag tag
          index = @tags[tag]
          @timers[index].first unless index.nil?
        end

        def clear_timer timer
          index = @timers.find_index { |o| o.last == timer }
          return if index.nil?

          @timers.delete_at(index)

          tag = @tags.key(index - 1)
          return if tag.nil?

          @tags.delete(tag)
          @tags.transform_values! { |e| e > index ? e - 1 : e }
        end

        def clear_tag tag
          index = @tags[tag]
          return if index.nil?

          @timers.delete_at(index)

          @tags.delete(tag)
          @tags.transform_values! { |e| e > index ? e - 1 : e }
        end

        def clear
          @timers.clear
          @tags.clear
        end
      end

      on :new do
        @timer = Component.new self
      end

      on :interval do |dt|
        (0...self.timer.timers.size).step(2).select do |e|
          self.timer.timers[e][0] -= dt
          self.timer.timers[e][0] <= 0
        end.each do |e|
          p = self.timer.timers[e][1]
          self.instance_exec(&p)
          self.timer.clear_timer p
        end
      end
    end
  end
end
