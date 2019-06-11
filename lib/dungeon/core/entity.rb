module Dungeon
  module Core
    class Entity
      class HandlerManager
        attr_reader :own
        attr_reader :cache
        attr_reader :push_index
        attr_reader :parent
        attr_reader :children

        def initialize parent = nil
          @own = (Hash.new { |h,k| h[k] = []})
          @cache = (Hash.new { |h,k| h[k] = []})
          @push_index = (Hash.new { |h,k| h[k] = 0})
          @parent = parent
          @children = []
          parent.children << self unless parent.nil?
        end

        def push message, p
          own[message.to_sym].push(p)
          rebuild_handler_cache

          proc do
            own[message.to_sym].delete(p)
            rebuild_handler_cache
          end
        end

        def unshift message, p
          own[message.to_sym].unshift(p)
          push_index[message.to_sym] += 1
          rebuild_handler_cache

          proc do
            own[message.to_sym].delete(p)
            push_index[message.to_sym] -= 1
            rebuild_handler_cache
          end
        end

        def rebuild_handler_cache
          @cache = (Hash.new { |h,k| h[k] = []})

          [ self ].tap do |o|
            o << o.last.parent until o.last.parent.nil?
          end.reverse.each do |e|
            e.own.each do |k,v|
              index = e.push_index[k]
              head = v.take(index)
              tail = v.drop(index)
              cache[k] = head + cache[k] + tail
            end
          end

          children.each { |e| e.rebuild_handler_cache }
        end
      end

      module ClassMethods
        attr_reader :handlers

        def on message, &block
          @handlers.push(message.to_sym, proc do |p, rcv, *args|
            rcv.instance_exec(*args, &block)
            p.call
          end)
        end

        def before message, &block
          around(message) do |p, *args|
            self.instance_exec(*args, &block)
            p.call
          end
        end

        def after message, &block
          around(message) do |p, *args|
            p.call
            self.instance_exec(*args, &block)
          end
        end

        def around message, &block
          @handlers.unshift(message.to_sym, proc do |p, rcv, *args|
            rcv.instance_exec(p, *args, &block)
          end)
        end

        def deliver reciever, message, *args
          return unless reciever.active?
          message = message.to_sym
          catch(:stop!) do
            target, index = 0, 0
            p = proc do
              if index < handlers.cache[message].size
                target, index = index, index + 1
                handlers.cache[message][target].call(p, reciever, *args)
              else
                yield if block_given?
              end
            end
            p.call
          end
        end

        def inherited klass
          super
          klass.instance_exec(self) do |_self|
            @handlers = HandlerManager.new _self.handlers
          end
        end

        def self.extended klass
          klass.instance_exec do
            @handlers = HandlerManager.new
          end
        end
      end

      def self.registry
        (@registry ||= [])
      end

      def self.inherited klass
        Entity.registry << klass
        klass.instance_eval do
          extend ClassMethods
        end
      end

      def self.id_counter
        (@id_counter ||= 0)
      end

      def self.id_counter= value
        @id_counter = value
      end

      def self.id_counter_next
        self.id_counter += 1
      end

      def self.new
        super(Entity.id_counter_next).tap { |o| o.emit(:new) }
      end

      attr_reader :id
      attr_accessor :parent
      attr_accessor :active
      alias_method :active?, :active

      def initialize id
        @id = id
        @active = true
        @klass = self.class
      end

      def broadcast message, *args
        peer, target = parent, self
        until peer.nil?
          peer, target = peer.parent, peer
        end
        target.emit message, *args
      end

      def emit message, *args
        @klass.deliver(self, message, *args) do
          self.send(:last, message.to_s, *args)
        end
      end

      def remove
        parent.remove(self) unless parent.nil?
      end

      def on message, &block
        if @klass == self.class
          @klass = class << self; self; end
          self.class.inherited(@klass)
        end
        @klass.on(message, &block)
      end

      def before message, &block
        if @klass == self.class
          @klass = class << self; self; end
          self.class.inherited(@klass)
        end
        @klass.before(message, &block)
      end

      def after message, &block
        if @klass == self.class
          @klass = class << self; self; end
          self.class.inherited(@klass)
        end
        @klass.after(message, &block)
      end

      def around message, &block
        if @klass == self.class
          @klass = class << self; self; end
          self.class.inherited(@klass)
        end
        @klass.around(message, &block)
      end

      def inactive?
        not active?
      end

      def activate!
        self.active = true
      end

      def deactivate!
        self.active = false
      end

      def toggle!
        self.active = !self.active
      end

      def to_h
        {
          "id" => self.id,
          "type" => self.class.to_s.
            split("::").
            map do |e|
              e.split(/(?=[A-Z])/).
              tap { |o| o.pop if o.last == "Entity" }.
              map { |e| e.downcase }.
              join("_")
            end.join("::"),
          "active" => self.active,
        }
      end

      def inspect
        "#<%s id=%i %s>" % [
          self.class,
          self.id,
          self.to_h.tap { |o| o.delete("id"); o.delete("type") }.to_a.map do |e|
            [ e[0].to_s, e[1].inspect ].join("=")
          end.join(" "),
        ]
      end

      private

      def initialize_copy source
        super
        @id = Entity.id_counter_next
        @parent = nil
        self.emit(:copy)
      end

      def stop! *args
        throw :stop!, *args
      end

      def last message, *args
        # stub for collections
      end
    end
  end
end
