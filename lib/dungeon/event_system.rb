require "dungeon/sdl"

module Dungeon
  class EventSystem
    class QuitEvent
    end

    class IntervalEvent
      attr_reader :now
      alias_method :t, :now
      attr_reader :dt

      def initialize now, dt
        @now = now
        @dt = dt
      end
    end

    class KeyEvent
      attr_reader :key_code
      attr_reader :scan_code

      def initialize key_code, scan_code
        @key_code = key_code
        @scan_code = scan_code
      end

      def key
        if key_code < 256
          key_code.chr
        else
          case scan_code
          when :SDL_SCANCODE_RIGHT
            "right"
          when :SDL_SCANCODE_LEFT
            "left"
          when :SDL_SCANCODE_DOWN
            "down"
          when :SDL_SCANCODE_UP
            "up"
          end
        end
      end
    end

    class KeydownEvent < KeyEvent; end
    class KeyupEvent < KeyEvent; end

    include Enumerable

    attr_reader :now

    def self.open *args
      if block_given?
        video = self.open(*args)
        yield video
        video.close
      else
        self.new.tap { |o| o.open(*args) }
      end
    end

    def open
      @event = SDL2::SDL_Event.new
      @now = 0
    end

    def each fps = nil, &block
      if block_given?
        self.each(fps).each(&block)
      else
        waitticks = fps.nil? ? 0 : (1000 / fps).to_i

        Enumerator.new do |yielder|
          begin
            catch :done do
              loop do
                @now, diff = _ticks_since @now

                _pump_events(yielder)
                yielder << IntervalEvent.new(@now, diff)

                diff2 = _ticks_since(@now)[1]
                SDL2.SDL_Delay(waitticks - diff2) if diff2 < waitticks
              end
            end
          rescue Interrupt
            yielder << QuitEvent.new
          end
        end
      end
    end

    def close
    end

    private

    def _ticks_since last
      now = SDL2.SDL_GetTicks
      now >= last ? [ now, now - last ] : [ now, now + (0xFFFFFFFF - last) ]
    end

    def _pump_events yielder
      flag = false

      while SDL2.SDL_PollEvent(@event) != 0
        case @event[:type]
        when SDL2::SDL_KEYUP
          yielder << KeyupEvent.new(@event[:key][:keysym][:sym],
                                    @event[:key][:keysym][:scancode])
        when SDL2::SDL_KEYDOWN
          if @event[:key][:repeat] == 0
            yielder << KeydownEvent.new(@event[:key][:keysym][:sym],
                                        @event[:key][:keysym][:scancode])
          end
        when SDL2::SDL_WINDOWEVENT
          if @event[:window][:event] == :SDL_WINDOWEVENT_CLOSE
            flag = true
            yielder << QuitEvent.new
          end
        when SDL2::SDL_QUIT
          flag = true
          yielder << QuitEvent.new
        end
      end

      throw :done if flag
    end
  end
end
