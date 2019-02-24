module Dungeon
  module Aspect
    module ClassMethods
      def on message, &block
        handlers.push([ :on, message, block ])
      end

      def before message, &block
        handlers.push([ :before, message, block ])
      end

      def after message, &block
        handlers.push([ :after, message, block ])
      end

      def around message, &block
        handlers.push([ :around, message, block ])
      end

      def handlers
        (@handlers ||= [])
      end

      def included klass
        handlers.each { |e| klass.send(e[0], e[1], &e[2]) }
      end
    end

    def self.included klass
      klass.instance_eval do
        extend Dungeon::Aspect::ClassMethods
      end
    end
  end
end
