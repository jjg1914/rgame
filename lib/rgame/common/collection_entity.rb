# frozen_string_literal: true

require "forwardable"
require "rgame/core/entity"

module RGame
  module Common
    class CollectionEntity < RGame::Core::Entity
      attr_reader :children

      extend Forwardable
      def_delegators :@children, :empty?

      def initialize id, context
        super
        @children = []
        @index = {}
      end

      def add_front target
        raise IndexError if @index.key? target.id

        @index.keys.each { |e| @index[e] += 1 }
        @index[target.id] = 0
        @children.unshift target

        target.parent = self
        target.emit "add"
      end

      def add_back target
        raise IndexError if @index.key? target.id

        @index[target.id] = @children.size
        @children.push target

        target.parent = self
        target.emit "add"
      end

      alias add add_back

      def add_bulk targets
        targets.each { |e| self.add(e) }
      end

      def create klass
        self.make(klass) do |o|
          self.add(o)
          yield o if block_given?
        end
      end

      def remove target = nil
        if target.nil?
          super()
        else
          index = @index.fetch target.id
          @children[index].emit "remove"
          @children[index].parent = nil

          @children.delete_at(index)
          @index.keys.each { |e| @index[e] -= 1 if @index[e] > index }
        end
      end

      def remove_bulk targets
        targets.each { |e| self.remove(e) }
      end

      def remove_all
        self.each { |e| self.remove(e) }
      end

      def each &block
        @children.each(&block)
      end

      def size
        @children.size
      end

      def inspect
        tmp = self.each.map(&:inspect).join("\n")
        ([ super ] + tmp.each_line.map { |e| "  " + e.chomp }).join("\n")
      end

      private

      def last message, *args
        return if message == "new"

        self.each { |e| e.emit(message, *args) }
      end
    end
  end
end
