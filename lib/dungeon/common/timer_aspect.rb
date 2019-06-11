require "dungeon/core/collision"
require "dungeon/core/aspect"

module Dungeon
  module Common
    module TimerAspect 
      include Dungeon::Core::Aspect

      attr_reader :timers

      on :new do
        @timers = []
      end

      on :interval do |dt|
        to_delete = []
        (0...self.timers.size).step(2).each do |e|
          self.timers[e] -= dt
          to_delete << e if self.timers[e] <= 0
        end

        to_delete.reverse_each do |e|
          self.timers[e + 1].call
          self.timers.delete_at(e + 1)
          self.timers.delete_at(e)
        end
      end

      def set_timer millis, &block
        self.timers << millis << block
        block
      end

      def poll_timer timer
        index = self.timers.find_index(timer)
        self.timer[index - 1] unless index.nil?
      end

      def clear_timer timer
        index = self.timers.find_index(timer)
        unless index.nil?
          self.timers.delete_at(index)
          self.timers.delete_at(index - 1)
        end
      end
    end
  end
end
