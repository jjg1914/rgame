require "thread"
require "readline"

module Dungeon
  module Core
    class ConsoleSystem
      class ConsoleExitException < Exception; end

      class ConsoleEvent
        attr_reader :args

        def initialize args
          @args = args
          @complete = false
          @mutex = Mutex.new
          @resource = ConditionVariable.new
        end

        def release
          @mutex.synchronize do
            @complete = true
            @resource.signal
          end
        end

        def await
          @mutex.synchronize do
            @resource.wait(@mutex, 1) until @complete
          end
        end
      end

      def self.open *args
        if block_given?
          tmp = self.open(*args)
          yield tmp
          tmp.close
        else
          self.new.tap { |o| o.open(*args) }
        end
      end

      def open application
        @application = application
        @thread = Thread.new { run }
      end

      def close
        @thread.raise(ConsoleExitException.new)
        @thread.join
      end

      def run
        begin
          if File.exist?(".consolehst")
            File.read(".consolehst").each_line do |e|
              Readline::HISTORY.push e.chomp
            end
          end

          while buf = Readline.readline(ENV.fetch("PS2", "> "), false)
            next if buf.strip.empty?
            Readline::HISTORY.push(buf) if Readline::HISTORY.empty? or buf != Readline::HISTORY[-1]

            ev = ConsoleEvent.new buf.split(/\s+/)
            @application.systems["event"] << ev if @application.systems.has_key? "event"
            ev.await
          end
        rescue ConsoleExitException
          unless Readline::HISTORY.empty?
            Readline::HISTORY.to_a.reverse.take(1000).reverse.tap do |o|
              File.write(".consolehst", o.join("\n") + "\n")
            end
          end
        end
      end
    end
  end
end
