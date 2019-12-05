# frozen_string_literal: true

require "forwardable"
require "rgame/core/entity"

module RGame
  module Common
    class QueueEntity < RGame::Core::Entity
      attr_reader :children

      extend Forwardable
      def_delegators :@children, :empty?, :size

      def initialize id, context
        super
        @children = []
      end

      def enqueue target
        @children.push target

        target.parent = self
        target.emit "enqueue"
      end

      def create klass
        self.make(klass) do |o|
          self.enqueue(o)
          yield o if block_given?
        end
      end

      def dequeue
        self.peek&.emit "dequeue"
        self.peek&.parent = nil

        @children.shift

        self.emit "empty" if self.empty?
      end

      def peek
        @children.first
      end

      private

      def last message, *args
        return if message == "new"

        self.peek&.emit(message, *args)
      end
    end
  end
end
