module Dungeon
  module Core
    class Entity
      module ClassMethods
        def on message, &block
          handlers[message.to_sym].push(proc do |p, rcv, *args|
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
          handlers[message.to_sym].unshift(proc do |p, rcv, *args|
            rcv.instance_exec(p, *args, &block)
          end)
        end

        def deliver reciever, message, *args
          return unless reciever.active?
          message = message.to_sym
          catch(:stop!) do
            target, index = 0, 0
            p = proc do
              if index < handlers[message].size
                target, index = index, index + 1
                handlers[message][target].call(p, reciever, *args)
              else
                reciever.send(:last, message, *args)
              end
            end
            p.call
          end
        end

        def handlers
          (@handlers ||= (Hash.new { |h,k| h[k] = []}))
        end
      end

      def self.inherited klass
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

      def self.new *args
        super(Entity.id_counter_next).tap { |o| o.emit(:new, *args) }
      end

      attr_reader :id
      attr_accessor :parent
      attr_accessor :active
      alias_method :active?, :active

      def initialize id
        @id = id
        @active = true
      end

      def broadcast message, *args
        peer, target = parent, self
        until peer.nil?
          peer, target = target.parent, peer
        end
        target.deliver message, *args
      end

      def emit message, *args
        self.class.deliver(self, message, *args)
      end

      def remove
        parent.remove(self) unless parent.nil?
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

      def try_send message, *args
        send(message, *args) if respond_to? message
      end

      private

      def stop! *args
        throw :stop!, *args
      end

      def last message, *args
        # stub for collections
      end
    end
  end
end
