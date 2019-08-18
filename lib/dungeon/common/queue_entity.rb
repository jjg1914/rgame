# frozen_string_literal: true

require "dungeon/core/entity"

module Dungeon
  module Common
    class QueueEntity < Dungeon::Core::Entity
      def initialize id, context
        super
        @children = []
      end

      def enqueue target
        @children.push target

        target.parent = self
        target.emit(:enqueue)
      end

      def create klass
        self.make(klass) do |o|
          yield o if block_given?
          self.enqueue(o)
        end
      end

      def dequeue
        self.peek&.emit(:dequeue)
        self.peek&.parent = nil

        @children.shift

        self.emit(:empty) if self.empty?
      end

      def peek
        @children.first
      end

      def size
        @children.size
      end

      def empty?
        self.size == 0
      end

      private

      def last message, *args
        return if message == "new"

        self.peek&.emit(message, *args)
      end
    end
  end
end
