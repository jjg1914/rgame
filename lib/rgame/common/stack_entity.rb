# frozen_string_literal: true

require "forwardable"
require "rgame/core/entity"

module RGame
  module Common
    class StackEntity < RGame::Core::Entity
      attr_reader :children

      extend Forwardable
      def_delegators :@children, :empty?, :size

      def initialize id, context
        super
        @children = []
      end

      def push target
        @children.push target

        target.parent = self
        target.emit "push"
      end

      def create klass
        self.make(klass) do |o|
          self.push(o)
          yield o if block_given?
        end
      end

      def pop
        self.peek&.emit "pop"
        self.peek&.parent = nil

        @children.pop

        self.emit "empty" if self.empty?
      end

      def swap target
        self.pop
        self.push target
      end

      def peek
        @children.last
      end

      private

      def last message, *args
        return if message == "new"

        self.peek&.emit(message, *args)
      end
    end
  end
end
