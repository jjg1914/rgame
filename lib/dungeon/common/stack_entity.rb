# frozen_string_literal: true

require "dungeon/core/entity"

module Dungeon
  module Common
    class StackEntity < Dungeon::Core::Entity
      def initialize id, context
        super
        @children = []
      end

      def push target
        @children.push target

        target.parent = self
        target.emit(:push)
      end

      def create klass
        self.make(klass) do |o|
          yield o if block_given?
          self.push(o)
        end
      end

      def pop
        self.peek&.emit(:pop)
        self.peek&.parent = nil

        @children.pop

        self.emit(:empty) if self.empty?
      end

      def swap target
        self.pop
        self.push target
      end

      def peek
        @children.last
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
