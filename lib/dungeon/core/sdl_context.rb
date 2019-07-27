# frozen_string_literal: true

require "forwardable"

require "dungeon/core/env"
require "dungeon/core/events"
require "dungeon/core/sdl"

module Dungeon
  module Core
    module SDLContext
      WINDOW_FLAGS = SDL2::SDL_WINDOW_SHOWN |
                     SDL2::SDL_WINDOW_OPENGL
      RENDERER_FLAGS = SDL2::SDL_RENDERER_ACCELERATED |
                       SDL2::SDL_RENDERER_PRESENTVSYNC

      SCAN_CODE_STRINGS = {
        :SDL_SCANCODE_RETURN => "return",
        :SDL_SCANCODE_ESCAPE => "escape",
        :SDL_SCANCODE_BACKSPACE => "backspace",
        :SDL_SCANCODE_TAB => "tab",
        :SDL_SCANCODE_SPACE => "space",
        :SDL_SCANCODE_F1 => "f1",
        :SDL_SCANCODE_F2 => "f2",
        :SDL_SCANCODE_F3 => "f3",
        :SDL_SCANCODE_F4 => "f4",
        :SDL_SCANCODE_F5 => "f5",
        :SDL_SCANCODE_F6 => "f6",
        :SDL_SCANCODE_F7 => "f7",
        :SDL_SCANCODE_F8 => "f8",
        :SDL_SCANCODE_F9 => "f9",
        :SDL_SCANCODE_F10 => "f10",
        :SDL_SCANCODE_F11 => "f11",
        :SDL_SCANCODE_F12 => "f12",
        :SDL_SCANCODE_INSERT => "insert",
        :SDL_SCANCODE_HOME => "home",
        :SDL_SCANCODE_PAGEUP => "page_up",
        :SDL_SCANCODE_DELETE => "delete",
        :SDL_SCANCODE_END => "end",
        :SDL_SCANCODE_PAGEDOWN => "page_down",
        :SDL_SCANCODE_RIGHT => "right",
        :SDL_SCANCODE_LEFT => "left",
        :SDL_SCANCODE_DOWN => "down",
        :SDL_SCANCODE_UP => "up",
        :SDL_SCANCODE_LCTRL => "left_ctrl",
        :SDL_SCANCODE_LSHIFT => "left_shift",
        :SDL_SCANCODE_LALT => "left_alt", # alt, option
        :SDL_SCANCODE_LGUI => "left_super", # windows, command (apple), meta
        :SDL_SCANCODE_RCTRL => "right_ctrl",
        :SDL_SCANCODE_RSHIFT => "right_shift",
        :SDL_SCANCODE_RALT => "right_alt", # alt gr, option
        :SDL_SCANCODE_RGUI => "right_super", # windows, command (apple), meta
        :SDL_SCANCODE_ENTER => "enter",
      }.freeze

      BUTTON_STRINGS = {
        SDL2::SDL_BUTTON_LEFT => "left",
        SDL2::SDL_BUTTON_MIDDLE => "middle",
        SDL2::SDL_BUTTON_RIGHT => "right",
        SDL2::SDL_BUTTON_X1 => "x1",
        SDL2::SDL_BUTTON_X2 => "x2",
      }.freeze

      def self.open title, width, height
        raise SDL2.SDL_GetError unless SDL2.SDL_Init(SDL2::SDL_INIT_VIDEO).zero?
        raise SDL2.SDL_GetError unless SDL2TTF.TTF_Init.zero?

        if SDL2Image.IMG_Init(SDL2Image::IMG_INIT_PNG).zero?
          raise SDL2.SDL_GetError
        end

        window = SDL2.SDL_CreateWindow title, 0, 0, width, height, WINDOW_FLAGS
        raise SDL2.SDL_GetError if window.nil?

        renderer = SDL2.SDL_CreateRenderer window, -1, RENDERER_FLAGS
        raise SDL2.SDL_GetError if renderer.nil?

        SDL2.SDL_StopTextInput

        Value.new window, renderer
      end

      class Value
        include Enumerable

        extend Forwardable
        def_delegators :@events, :now, :fps, :fps=, :<<, :each, :each_event
        def_delegators :@stack, :save, :restore
        def_delegators :@state,
                       :target, :target=,
                       :source, :source=,
                       :color, :color=,
                       :alpha, :alpha=,
                       :scale, :scale=,
                       :scale_quality, :scale_quality=,
                       :font, :font=,
                       :text_input_mode, :text_input_mode=,
                       :clip_bounds, :clip_bounds=

        def initialize window, renderer
          @window = window
          @renderer = renderer

          @mem_ints = 8.times.map { FFI::MemoryPointer.new(:int, 1) }
          @sdl_rects = 2.times.map { SDL2::SDLRect.new }

          @state = StateHolder.new @renderer
          @stack = StateSaver.new(self, %w[
            fps
            target
            source
            color
            alpha
            scale
            scale_quality
            font
            text_input_mode
            clip_bounds
          ])

          @events = EventSource.new
        end

        def close
          SDL2.SDL_DestroyRenderer @renderer unless @renderer.nil?
          SDL2.SDL_DestroyWindow @window unless @window.nil?
          SDL2TTF.TTF_Quit
          SDL2Image.IMG_Quit
          SDL2.SDL_Quit
        end

        def present
          SDL2.SDL_RenderPresent @renderer
        end

        def create_image width, height
          format = SDL2.SDL_GetWindowPixelFormat(@window)
          texture = SDL2.SDL_CreateTexture(@renderer, format,
                                           SDL2::SDL_TEXTUREACCESS_TARGET,
                                           width, height)
          Image.new texture
        end

        def create_text text
          return if @state.font_pointer.nil? or @state.font_pointer.null?

          surface = SDL2TTF.TTF_RenderText_Solid @state.font_pointer,
                                                 text,
                                                 @state.color_struct
          texture = SDL2.SDL_CreateTextureFromSurface(@renderer, surface)
          SDL2.SDL_FreeSurface(surface)

          Image.new texture
        end

        def size_of_text text
          if @state.font_pointer.nil? or @state.font_pointer.null?
            [ 0, 0 ]
          else
            SDL2TTF.TTF_SizeText(@state.font_pointer,
                                 text, @mem_ints[0], @mem_ints[1])
            [ @mem_ints[0].get(:int, 0), @mem_ints[1].get(:int, 0) ]
          end
        end

        def clear
          SDL2.SDL_RenderClear @renderer
        end

        def stroke_rect x, y, width, height
          @sdl_rects[0][:x] = x
          @sdl_rects[0][:y] = y
          @sdl_rects[0][:w] = width
          @sdl_rects[0][:h] = height
          SDL2.SDL_RenderDrawRect(@renderer, @sdl_rects[0])
        end

        def fill_rect x, y, width, height
          @sdl_rects[0][:x] = x
          @sdl_rects[0][:y] = y
          @sdl_rects[0][:w] = width
          @sdl_rects[0][:h] = height
          SDL2.SDL_RenderFillRect(@renderer, @sdl_rects[0])
        end

        def draw_image x, y, dx = 0, dy = 0, width = nil, height = nil
          @sdl_rects[0][:x] = x
          @sdl_rects[0][:y] = y
          @sdl_rects[0][:w] = width || @state.source_image.width
          @sdl_rects[0][:h] = height || @state.source_image.height
          @sdl_rects[1][:x] = dx
          @sdl_rects[1][:y] = dy
          @sdl_rects[1][:w] = width || @state.source_image.width
          @sdl_rects[1][:h] = height || @state.source_image.height
          SDL2.SDL_RenderCopy(@renderer,
                              @state.source_image.texture,
                              @sdl_rects[1],
                              @sdl_rects[0])
        end
      end

      class Image
        attr_accessor :name
        attr_accessor :path
        attr_reader :texture
        attr_reader :width
        attr_reader :height

        def initialize texture
          @texture = texture

          mem_ints = 2.times.map { FFI::MemoryPointer.new(:int, 1) }
          SDL2.SDL_QueryTexture(texture, nil, nil, mem_ints[0], mem_ints[1])
          @width = mem_ints[0].get(:int, 0)
          @height = mem_ints[1].get(:int, 0)

          ObjectSpace.define_finalizer(self, &self.method(:free))
        ensure
          mem_ints&.each { |e| e&.free }
        end

        def free
          return if @texture.nil?

          SDL2.SDL_DestroyTexture @texture
          @texture = nil
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def texture_blend_mode
          mem_int = FFI::MemoryPointer.new(:int, 1)
          SDL2.SDL_GetTextureBlendMode @texture, mem_int
          case mem_int.get(:int, 0)
          when SDL2::SDL_BLENDMODE_NONE
            "none"
          when SDL2::SDL_BLENDMODE_BLEND
            "blend"
          when SDL2::SDL_BLENDMODE_ADD
            "add"
          when SDL2::SDL_BLENDMODE_MOD
            "mod"
          else
            "invalid"
          end
        ensure
          mem_int.free unless mem_int.nil? or mem_int.null?
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def texture_blend_mode= value
          mode = case value
          when "none"
            SDL2::SDL_BLENDMODE_NONE
          when "blend"
            SDL2::SDL_BLENDMODE_BLEND
          when "add"
            SDL2::SDL_BLENDMODE_ADD
          when "mod"
            SDL2::SDL_BLENDMODE_MOD
          else
            SDL2::SDL_BLENDMODE_INVALID
          end

          SDL2.SDL_SetTextureBlendMode(@target, mode)
        end
      end

      module TextInputState
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
      end

      class StateHolder
        include TextInputState

        attr_reader :target
        attr_reader :source
        attr_reader :color
        attr_reader :alpha
        attr_reader :scale
        attr_reader :scale_quality
        attr_reader :font
        attr_reader :clip_bounds

        attr_reader :font_pointer
        attr_reader :color_struct
        attr_reader :source_image

        def initialize renderer
          @renderer = renderer

          @color = 0x000000
          @alpha = 0xFF
          @scale = 1
          @scale_quality = SDL2.SDL_GetHint(SDL2::SDL_HINT_RENDER_SCALE_QUALITY)

          @color_struct = SDL2::SDLColor.new
          @sdl_rect = SDL2::SDLRect.new
          @font_cache = {}
          @font_cache = Hash.new { |h, k| h[k] = _load_font(k) }
          @image_cache = Hash.new { |h, k| h[k] = _load_image(k) }

          mem_int = FFI::MemoryPointer.new(:uint8, 4)
          SDL2.SDL_GetRenderDrawColor @renderer, mem_int, mem_int + 1,
                                      mem_int + 2, mem_int + 3
          @color = _from_rgb(mem_int.get(:uint8, 0),
                             mem_int.get(:uint8, 1),
                             mem_int.get(:uint8, 2))
          @alpha = mem_int.get(:uint8, 3)

          self.text_input_mode = false
        ensure
          mem_int.free unless mem_int.nil? or mem_int.null?
        end

        def color= value
          return if @color == value

          red, green, blue = _to_rgb(value)
          SDL2.SDL_SetRenderDrawColor @renderer, red, green, blue, alpha
          @color_struct.assign red, green, blue, value
          @color = value
        end

        def alpha= value
          return if @alpha == value

          red, green, blue = _to_rgb(color)
          SDL2.SDL_SetRenderDrawColor @renderer, red, green, blue, value
          @color_struct.assign red, green, blue, value
          @alpha = value
        end

        def scale= value
          value = [ value, value ] unless value.is_a? Array
          value = if value.empty?
            [ 1.0, 1.0 ]
          elsif value.size == 1
            [ value[0].to_f, value[0].to_f ]
          else
            value.take(2).map(&:to_f)
          end

          return if @scale == value

          SDL2.SDL_RenderSetScale @renderer, value[0], value[1]
          @scale = value
        end

        def scale_quality= value
          return if @scale_quality == value

          SDL2.SDL_SetHint(SDL2::SDL_HINT_RENDER_SCALE_QUALITY, value.to_s)
          @scale_quality = value
        end

        def target= value
          return if @target == value

          SDL2.SDL_SetRenderTarget(@renderer, value)
          @target = value
        end

        def source= value
          return if @source == value

          @source_image = if value.is_a? Image
            value
          else
            @image_cache[value.to_s]
          end
          @source = value
        end

        def font= value
          return if @font == value

          @font_pointer = (@font_cache[value] unless value.nil?)
          @font = value
        end

        def clip_bounds= value
          return if @clip_bounds == value

          if value.nil?
            SDL2.SDL_RenderSetClipRect @renderer, nil
          else
            @sdl_rect[:x] = value["left"]
            @sdl_rect[:y] = value["top"]
            @sdl_rect[:w] = value["right"] - value["left"] + 1
            @sdl_rect[:h] = value["bottom"] - value["top"] + 1

            SDL2.SDL_RenderSetClipRect @renderer, @sdl_rect
          end

          @clip_bounds = value
        end

        private

        def _load_font value
          name, size = value.to_s.split(":", 2).map(&:strip)

          path = Env.font_path.split(":").map do |e|
            File.expand_path("%s.ttf" % name, e.strip)
          end.find do |e|
            File.exist?(e)
          end
          raise "font not found %s" % value.inspect if path.nil?

          SDL2TTF.TTF_OpenFont path, size.to_i
        end

        def _load_image value
          path = Env.image_path.split(":").map do |e|
            File.expand_path("%s.png" % value, e.strip)
          end.find do |e|
            File.exist?(e)
          end
          raise "image not found %s" % value.inspect if path.nil?

          surface = SDL2Image.IMG_Load path
          texture = SDL2.SDL_CreateTextureFromSurface @renderer, surface

          Image.new(texture).tap do |o|
            SDL2.SDL_FreeSurface surface
            o.name = File.basename(value)
            o.path = path
          end
        end

        def _to_rgb rgb
          [ _red_value(rgb), _green_value(rgb), _blue_value(rgb) ]
        end

        def _from_rgb red, green, blue
          (red << 16) | (green << 8) | blue
        end

        def _red_value rgba
          # TODO ENDIAN
          (rgba & 0x00FF0000) >> 16
        end

        def _green_value rgba
          # TODO ENDIAN
          (rgba & 0x0000FF00) >> 8
        end

        def _blue_value rgba
          # TODO ENDIAN
          (rgba & 0x000000FF)
        end

        def _alpha_value rgba
          # TODO ENDIAN
          (rgba & 0xFF000000) >> 24
        end
      end

      class StateSaver
        def initialize target, props
          @target = target
          @props = props

          @stack = []
        end

        def save
          @stack << @props.map { |e| @target.send(e) }
          return unless block_given?

          begin
            yield
          ensure
            self.restore
          end
        end

        def restore
          return if @stack.empty?

          @props.zip(@stack.pop).each { |k, v| @target.send(("%s=" % k), v) }
        end
      end

      class EventSource
        attr_reader :now
        attr_accessor :fps

        def initialize
          @mutex = Mutex.new

          @modifiers = ModifierState.new
          @event_buffer = []

          @sdl_event = SDL2::SDLEvent.new

          @now = 0
          @fps = 60
        end

        def each_event &block
          return self.each_event.each(&block) if block_given?

          waitticks = self.fps.nil? ? 0 : (1000 / self.fps).to_i

          Enumerator.new do |yielder|
            catch :done do
              loop do
                flag = false
                @now, diff = _ticks_since @now

                _pump_events.each do |e|
                  yielder << e
                  flag ||= e.is_a?(Dungeon::Core::Events::QuitEvent)
                end
                throw :done if flag
                yielder << Events::IntervalEvent.new(@now, diff)

                diff2 = _ticks_since(@now)[1]
                SDL2.SDL_Delay(waitticks - diff2) if diff2 < waitticks
              end
            end
          end
        end

        alias each each_event

        def << event
          self.tap { @mutex.synchronize { @event_buffer << event } }
        end

        private

        def _ticks_since last
          now = SDL2.SDL_GetTicks
          now >= last ? [ now, now - last ] : [ now, now + (0xFFFFFFFF - last) ]
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def _pump_events
          rval = _read_event_buffer

          until SDL2.SDL_PollEvent(@sdl_event).zero?
            case @sdl_event[:type]
            when SDL2::SDL_KEYUP
              rval << _pump_key_up
            when SDL2::SDL_KEYDOWN
              rval << _pump_key_down
            when SDL2::SDL_TEXTINPUT
              rval << _pump_text_input
            when SDL2::SDL_MOUSEMOTION
              rval << _pump_mouse_move
            when SDL2::SDL_MOUSEBUTTONDOWN
              rval << _pump_mouse_down
            when SDL2::SDL_MOUSEBUTTONUP
              rval << _pump_mouse_up
            when SDL2::SDL_WINDOWEVENT
              if @sdl_event[:window][:event] == :SDL_WINDOWEVENT_CLOSE
                rval << Events::QuitEvent.new
              end
            when SDL2::SDL_QUIT
              rval << Events::QuitEvent.new
            end
          end

          rval
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def _pump_key_up
          _assign_modifier @sdl_event, false

          key = _key_for(@sdl_event[:key][:keysym][:sym],
                         @sdl_event[:key][:keysym][:scancode])
          Events::KeyupEvent.new(key, @modifiers)
        end

        def _pump_key_down
          key = _key_for(@sdl_event[:key][:keysym][:sym],
                         @sdl_event[:key][:keysym][:scancode])
          if @sdl_event[:key][:repeat].zero?
            _assign_modifier @sdl_event, true

            Events::KeydownEvent.new(key, @modifiers)
          else
            Events::KeyrepeatEvent.new(key, @modifiers)
          end
        end

        def _pump_text_input
          text = @sdl_event[:text][:text].to_ptr.read_string
          Events::TextInputEvent.new(text)
        end

        def _pump_mouse_move
          Events::MouseMoveEvent.new(@sdl_event[:motion][:x],
                                     @sdl_event[:motion][:y],
                                     @modifiers)
        end

        def _pump_mouse_down
          button = _button_for @sdl_event[:button][:button]
          Events::MouseButtondownEvent.new(@sdl_event[:button][:x],
                                           @sdl_event[:button][:y],
                                           button,
                                           @modifiers)
        end

        def _pump_mouse_up
          button = _button_for @sdl_event[:button][:button]
          Events::MouseButtonupEvent.new(@sdl_event[:button][:x],
                                         @sdl_event[:button][:y],
                                         button,
                                         @modifiers)
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def _assign_modifier sdl_event, value
          case sdl_event[:key][:keysym][:scancode]
          when :SDL_SCANCODE_LCTRL
            @modifiers.left_ctrl = value
          when :SDL_SCANCODE_LSHIFT
            @modifiers.left_shift = value
          when :SDL_SCANCODE_LALT
            @modifiers.left_alt = value
          when :SDL_SCANCODE_LGUI
            @modifiers.left_super = value
          when :SDL_SCANCODE_RCTRL
            @modifiers.right_ctrl = value
          when :SDL_SCANCODE_RSHIFT
            @modifiers.right_shift = value
          when :SDL_SCANCODE_RALT
            @modifiers.right_alt = value
          when :SDL_SCANCODE_RGUI
            @modifiers.right_super = value
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def _read_event_buffer
          [].tap do |rval|
            unless @event_buffer.empty?
              @mutex.synchronize do
                rval.concat(@event_buffer)
                @event_buffer.clear
              end
            end
          end
        end

        def _key_for key_code, scan_code
          SCAN_CODE_STRINGS.fetch(scan_code, if key_code < 256
            key_code.chr
          else
            scan_code
          end)
        end

        def _button_for button
          BUTTON_STRINGS.fetch(button, button)
        end
      end

      class ModifierState
        attr_accessor :left_ctrl
        attr_accessor :left_shift
        attr_accessor :left_alt
        attr_accessor :left_super
        attr_accessor :right_ctrl
        attr_accessor :right_shift
        attr_accessor :right_alt
        attr_accessor :right_super

        def initialize
          @left_ctrl = false
          @left_shift = false
          @left_alt = false
          @left_super = false
          @right_ctrl = false
          @right_shift = false
          @right_alt = false
          @right_super = false
        end

        def ctrl
          self.left_ctrl or self.right_ctrl
        end

        def shift
          self.left_shift or self.right_shift
        end

        def alt
          self.left_alt or self.right_alt
        end

        def super
          self.left_super or self.right_super
        end

        def == other
          other.is_a?(self.class) and
            self.is_a?(other.class) and
            (%i[
              left_ctrl
              left_shift
              left_alt
              left_super
              right_ctrl
              right_shift
              right_alt
              right_super
            ].all? { |e| self.send(e) == other.send(e) })
        end
      end
    end
  end
end
