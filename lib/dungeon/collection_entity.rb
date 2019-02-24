require "dungeon/entity"

module Dungeon
  class CollectionEntity < Dungeon::Entity
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
        @tail = target.id
      end

      target.emit(:add)
    end

    def remove target = nil
      unless target.nil?
        child = @children.fetch target.id
        child[:target].emit(:remove)
        @children.delete child[:target].id
      else
        super()
      end
    end

    private

    def last message, *args
      index = @head
      until index.nil?
        @children[index][:target].emit(message, *args)
        index = @children[index][:next]
      end
    end
  end
end
