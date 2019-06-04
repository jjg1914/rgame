require "forwardable"
require "dungeon/core/entity"

module Dungeon
  module Common
    class CollectionEntity < Dungeon::Core::Entity
      attr_reader :children

      extend Forwardable
      def_delegators :@children, :empty?

      def initialize id
        super
        @children = []
        @index = {}
      end

      def add_front target
        raise IndexError if @index.has_key? target.id
        @index.keys.each { |e| @index[e] += 1 }
        @index[target.id] = 0
        @children.unshift target

        target.parent = self
        target.emit(:add)
      end

      def add_back target
        raise IndexError if @index.has_key? target.id
        @index[target.id] = @children.size
        @children.push target

        target.parent = self
        target.emit(:add)
      end

      alias_method :add, :add_back

      def add_bulk targets
        targets.each { |e| self.add(e) }
      end

      def remove target = nil
        unless target.nil?
          index = @index.fetch target.id
          @children[index].emit(:remove)
          @children[index].parent = nil

          @children.delete_at(index)
          @index.keys.each { |e| @index[e] -= 1 if @index[e] > index }
        else
          super()
        end
      end

      def remove_bulk targets
        targets.each { |e| self.remove(e) }
      end

      def remove_all
        self.each { |e| self.remove(e) }
      end

      def each(&b)
        @children.each(&b)
      end

      def inspect
        tmp = self.each.map { |e| e.inspect }.join("\n")
        ([ super ] + tmp.each_line.map { |e| "  " + e.chomp }).join("\n")
      end

      private

      def last message, *args
        unless message == "new"
          self.each { |e| e.emit(message, *args) }
        end
      end
    end
  end
end
