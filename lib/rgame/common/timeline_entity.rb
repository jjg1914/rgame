# frozen_string_literal: true

require "rgame/core/entity"
require "rgame/common/timer_aspect"

module RGame
  module Common
    class TimelineEntity < RGame::Core::Entity
      include RGame::Common::TimerAspect

      @timeline = Hash.new { |h, k| h[k] = [] }

      on "new" do
        self.class.timeline.reject do |k, _v|
          k.is_a? String
        end.each do |k, v|
          self.timer.set_timer(k) do
            v.each { |e| self.instance_eval(&e) }
          end
        end

        if self.class.timeline.key? "start"
          self.timer.set_timer(0) do
            self.class.timeline["start"].each { |e| self.instance_eval(&e) }
          end
        end

        if self.class.timeline.key? "end"
          self.class.timeline.keys.reject do |e|
            e.is_a? String
          end.max.tap do |o|
            self.timer.set_timer(o) do
              self.class.timeline["end"].each { |e| self.instance_eval(&e) }
            end
          end
        end
      end

      class << self
        attr_reader :timeline
        attr_accessor :cursor
        alias set_time cursor=

        def inherited klass
          super
          klass.instance_exec(@timeline) do |tl|
            @timeline = tl.dup
            @cursor = 0
            @offset = 0
          end
        end

        def at_start &block
          @timeline["start"] << block if block_given?
        end

        def at_end &block
          @timeline["end"] << block if block_given?
        end

        def at_cursor &block
          @timeline[@offset + @cursor] << block if block_given?
        end

        def at_time time, &block
          @cursor = time
          at_cursor(&block)
        end

        def at_time_diff diff, &block
          @cursor += diff
          at_cursor(&block)
        end

        def with_time time
          old_offset = @offset
          old_cursor = @cursor
          begin
            @offset = time
            @cursor = 0
            yield if block_given?
          ensure
            @offset = old_offset
            @cursor = old_cursor
          end
        end
      end
    end
  end
end
