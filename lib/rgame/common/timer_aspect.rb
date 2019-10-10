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
          @timers << millis << block
          block
        end

        def poll_timer timer
          index = @timers.find_index(timer)
          @timer[index - 1] unless index.nil?
        end

        def poll_tag tag
          index = @tags[tag]
          @timer[index] unless index.nil?
        end

        def clear_timer timer
          index = @timers.find_index(timer)
          return if index.nil?

          @timers.delete_at(index)
          @timers.delete_at(index - 1)

          tag = @tags.key(index - 1)
          return if tag.nil?

          @tags.delete(tag)
          @tags.transform_values! { |e| e > index ? e - 2 : e }
        end

        def clear_tag tag
          index = @tags[tag]
          return if index.nil?

          @timers.delete_at(index + 1)
          @timers.delete_at(index)

          @tags.delete(tag)
          @tags.transform_values! { |e| e > index ? e - 2 : e }
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
          self.timer.timers[e] -= dt
          self.timer.timers[e] <= 0
        end.each do |e|
          self.instance_exec(&self.timer.timers[e + 1])
          self.timer.clear_timer self.timer.timers[e]
        end
      end
    end
  end
end
