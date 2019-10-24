# frozen_string_literal: true

module RGame
  module Core
    class SDLContext
      class StateSaver
        def initialize props
          @props = props

          @stack = []
        end

        def save
          @stack << @props.map { |target, name| target.send(name) }
          return unless block_given?

          begin
            yield
          ensure
            self.restore
          end
        end

        def restore
          return if @stack.empty?

          @props.zip(@stack.pop).each { |a, b| a[0].send(("%s=" % a[1]), b) }
        end
      end
    end
  end
end
