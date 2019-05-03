require "dungeon/core/entity"

module Dungeon
  module Common
    class CollectionEntity < Dungeon::Core::Entity
      attr_reader :children

      def initialize id
        super
        @children = {}
        @head = nil
        @tail = nil
      end

      def add target
        raise IndexError if @children.has_key? target.id
        @children[target.id] = {
          :target => target,
        }

        if @head.nil?
          @head = target.id
          @tail = target.id
        else
          @children[@tail][:next] = target.id
          @children[target.id][:prev] = @tail
          @tail = target.id
        end

        target.parent = self
        target.emit(:add)
      end

      def add_bulk targets
        targets.each { |e| self.add(e) }
      end

      def remove target = nil
        unless target.nil?
          child = @children.fetch target.id
          child[:target].emit(:remove)
          child[:target].parent = nil
          @children[child[:prev]][:next] = child[:next] unless child[:prev].nil?
          @children[child[:next]][:prev] = child[:prev] unless child[:next].nil?
          @children.delete child[:target].id
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

      def each
        if block_given?
          self.each.each { |e| yield e }
        else
          Enumerator.new do |y|
            index = @head
            until index.nil?
              n = @children[index][:next]
              y << @children[index][:target]
              index = n
            end
          end
        end
      end

      private

      def last message, *args
        unless message == :new
          self.each { |e| e.emit(message, *args) }
        end
      end
    end
  end
end
