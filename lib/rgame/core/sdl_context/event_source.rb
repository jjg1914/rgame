# frozen_string_literal: true

require "rgame/core/events"
require "rgame/core/sdl"

module RGame
  module Core
    class SDLContext
      class EventSource
        def initialize
          super
          @queue = Queue.new

          self.text_input_mode = false
        end

        def each_event fps = nil, &block
          return self.each_event(fps).each(&block) if block_given?

          waitticks = fps.nil? ? 0 : (1000 / fps).to_i

          Enumerator.new do |yielder|
            catch :done do
              sdl_event = SDL2::SDLEvent.new
              modifiers = RGame::Core::Events::ModifierState.new
              now = 0

              loop do
                flag = false
                now, diff = _ticks_since now

                _pump_events(sdl_event, modifiers).each do |e|
                  yielder << e
                  flag ||= e.is_a?(RGame::Core::Events::QuitEvent)
                end
                throw :done if flag
                yielder << Events::IntervalEvent.new(now, diff)

                diff2 = _ticks_since(now)[1]
                SDL2.SDL_Delay(waitticks - diff2) if diff2 < waitticks
              end
            end
          end
        end

        alias each each_event

        def << event
          self.tap { @queue.push event }
        end

        def quit!
          self << RGame::Core::Events::QuitEvent.new
        end

        def text_input_mode
          @text_input_mode ||= SDL2.SDL_IsTextInputActive
        end

        def text_input_mode= value
          if (self.text_input_mode or value) and
             not (self.text_input_mode and value)
            if value
              SDL2.SDL_StartTextInput
            else
              SDL2.SDL_StopTextInput
            end
          end
          @text_input_mode = value
        end

        private

        def _ticks_since last
          now = SDL2.SDL_GetTicks
          now >= last ? [ now, now - last ] : [ now, now + (0xFFFFFFFF - last) ]
        end

        def _pump_events sdl_event, modifiers
          [].tap do |rval|
            rval << @queue.pop until @queue.empty?

            until SDL2.SDL_PollEvent(sdl_event).zero?
              _pump_event rval, sdl_event, modifiers
            end
          end
        end

        SDL_EVENT_MAP = {
          SDL2::SDL_KEYUP => Events::KeyupEvent,
          SDL2::SDL_KEYDOWN => Events::KeydownEvent,
          SDL2::SDL_TEXTINPUT => Events::TextInputEvent,
          SDL2::SDL_MOUSEMOTION => Events::MouseMoveEvent,
          SDL2::SDL_MOUSEBUTTONDOWN => Events::MouseButtondownEvent,
          SDL2::SDL_MOUSEBUTTONUP => Events::MouseButtonupEvent,
        }.freeze

        # rubocop:disable Metrics/CyclomaticComplexity
        def _pump_event rval, sdl_event, modifiers
          case sdl_event[:type]
          when SDL2::SDL_KEYUP
            _assign_modifier sdl_event, modifiers, false
          when SDL2::SDL_KEYDOWN
            _assign_modifier sdl_event, modifiers, true
          end

          ev = case sdl_event[:type]
          when SDL2::SDL_WINDOWEVENT
            if sdl_event[:window][:event] == :SDL_WINDOWEVENT_CLOSE
              Events::QuitEvent.new
            end
          when SDL2::SDL_QUIT
            Events::QuitEvent.new
          else
            SDL_EVENT_MAP[sdl_event[:type]]&.from_sdl(sdl_event, modifiers)
          end
          rval << ev unless ev.nil?
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        # rubocop:disable Metrics/CyclomaticComplexity
        def _assign_modifier sdl_event, modifiers, value
          case sdl_event[:key][:keysym][:scancode]
          when :SDL_SCANCODE_LCTRL
            modifiers.left_ctrl = value
          when :SDL_SCANCODE_LSHIFT
            modifiers.left_shift = value
          when :SDL_SCANCODE_LALT
            modifiers.left_alt = value
          when :SDL_SCANCODE_LGUI
            modifiers.left_super = value
          when :SDL_SCANCODE_RCTRL
            modifiers.right_ctrl = value
          when :SDL_SCANCODE_RSHIFT
            modifiers.right_shift = value
          when :SDL_SCANCODE_RALT
            modifiers.right_alt = value
          when :SDL_SCANCODE_RGUI
            modifiers.right_super = value
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity
      end
    end
  end
end
