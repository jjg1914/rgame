require "rgame/core/sdl_context" 

describe RGame::Core::SDLContext do
  describe RGame::Core::SDLContext::EventSource do
    describe "#each_event" do
      before do
        @sdl_event = RGame::Core::SDL2::SDLEvent.new
        nil until RGame::Core::SDL2.SDL_PollEvent(@sdl_event).zero?

        @modifiers = RGame::Core::SDLContext::ModifierState.new

        @subject = Object.new.tap do |o|
          o.instance_eval do 
            extend RGame::Core::SDLContext::EventSource
            extend MonitorMixin

            class << self
            end
          end
        end
      end

      it "should yield custom events" do
        @subject << "a" << "b" << "c"
        @subject << RGame::Core::Events::QuitEvent.new

        expect(@subject.each_event.to_a).must_equal([
          "a",
          "b",
          "c",
          RGame::Core::Events::QuitEvent.new
        ])
      end

      it "should yield quit event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::QuitEvent.new
        ])
      end

      it "should yield window close event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_WINDOWEVENT
        @sdl_event[:window][:event] = :SDL_WINDOWEVENT_CLOSE
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::QuitEvent.new
        ])
      end

      it "should not yield other window event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_WINDOWEVENT
        @sdl_event[:window][:event] = :SDL_WINDOWEVENT_NONE
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::QuitEvent.new
        ])
      end

      it "should yield interval event" do
        events = []
        ticks = []

        @subject.each_event do |e|
          if events.empty?
            ticks << e.t

            @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
            RGame::Core::SDL2.SDL_PushEvent @sdl_event
          end

          events << e
        end

        expect(events).must_equal([
          RGame::Core::Events::IntervalEvent.new(ticks[0].to_i, ticks[0].to_i),
          RGame::Core::Events::QuitEvent.new
        ])
      end

      it "should yield all interval events" do
        events = []

        mock = MiniTest::Mock.new
        mock.expect :getticks, 0, []
        mock.expect :getticks, 5, []
        mock.expect :delay, nil, [ 11 ]
        mock.expect :getticks, 16, []
        mock.expect :getticks, 19, []
        mock.expect :delay, nil, [ 13 ]
        mock.expect :getticks, 32, []
        mock.expect :getticks, 36, []
        mock.expect :delay, nil, [ 12 ]
        mock.expect :getticks, 48, []
        mock.expect :getticks, 49, []
        mock.expect :delay, nil, [ 15 ]
        mock.expect :getticks, 64, []

        RGame::Core::SDL2.stub(:SDL_Delay, lambda { |x| mock.delay(x) }) do
          RGame::Core::SDL2.stub(:SDL_GetTicks, lambda do
            mock.getticks
          end) do
            @subject.each_event(60) do |e|
              if events.size == 3
                @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
                RGame::Core::SDL2.SDL_PushEvent @sdl_event
              end
              events << e
            end
          end
        end


        expect(events.take(4).map(&:t).each_cons(2).all? do |a,b|
          (a - b).abs == 16
        end).must_equal(true)

        mock.verify
      end

      it "should yield key up event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYUP
        @sdl_event[:key][:keysym][:sym] = "a".bytes.first
        @sdl_event[:key][:keysym][:scancode] = 0
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeyupEvent.new("a", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield named key up event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYUP
        @sdl_event[:key][:keysym][:sym] = "a".bytes.first
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_RETURN
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeyupEvent.new("return", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield unknown key up event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYUP
        @sdl_event[:key][:keysym][:sym] = 312
        @sdl_event[:key][:keysym][:scancode] = 0
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeyupEvent.new(:SDL_SCANCODE_UNKNOWN, @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield key repeat event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = "a".bytes.first
        @sdl_event[:key][:keysym][:scancode] = 0
        @sdl_event[:key][:repeat] = 1
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeyrepeatEvent.new("a", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end


      it "should yield lctrl key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_LCTRL
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.left_ctrl = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("left_ctrl", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield lshift key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_LSHIFT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.left_shift = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("left_shift", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield lalt key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_LALT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.left_alt = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("left_alt", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield lgui key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_LGUI
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.left_super = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("left_super", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield rctrl key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_RCTRL
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.right_ctrl = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("right_ctrl", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield rshift key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_RSHIFT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.right_shift = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("right_shift", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield ralt key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_RALT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.right_alt = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("right_alt", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield rgui key down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_KEYDOWN
        @sdl_event[:key][:keysym][:sym] = 0
        @sdl_event[:key][:keysym][:scancode] = :SDL_SCANCODE_RGUI
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @modifiers.right_super = true

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::KeydownEvent.new("right_super", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield text input event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_TEXTINPUT
        @sdl_event[:text][:text].to_ptr.put_string(0, "_str_")
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::TextInputEvent.new("_str_"),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield mouse motion event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_MOUSEMOTION
        @sdl_event[:motion][:x] = 123
        @sdl_event[:motion][:y] = 456
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::MouseMoveEvent.new(123, 456, @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield mouse down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_MOUSEBUTTONDOWN
        @sdl_event[:button][:x] = 123
        @sdl_event[:button][:y] = 456
        @sdl_event[:button][:button] = RGame::Core::SDL2::SDL_BUTTON_X1
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::MouseButtondownEvent.new(123, 456, "x1", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield mouse up event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_MOUSEBUTTONUP
        @sdl_event[:button][:x] = 123
        @sdl_event[:button][:y] = 456
        @sdl_event[:button][:button] = RGame::Core::SDL2::SDL_BUTTON_X1
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::MouseButtonupEvent.new(123, 456, "x1", @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end

      it "should yield unknown mouse down event" do
        @sdl_event[:type] = RGame::Core::SDL2::SDL_MOUSEBUTTONDOWN
        @sdl_event[:button][:x] = 123
        @sdl_event[:button][:y] = 456
        @sdl_event[:button][:button] = 42
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        @sdl_event[:type] = RGame::Core::SDL2::SDL_QUIT
        RGame::Core::SDL2.SDL_PushEvent @sdl_event

        expect(@subject.each_event.to_a).must_equal([
          RGame::Core::Events::MouseButtondownEvent.new(123, 456, 42, @modifiers),
          RGame::Core::Events::QuitEvent.new,
        ])
      end
    end
  end

  describe RGame::Core::SDLContext::ModifierState do
    before do
      @subject = RGame::Core::SDLContext::ModifierState.new
    end

    describe "#ctrl" do
      it "should be false" do
        expect(@subject.ctrl).must_equal false
      end

      it "should be true when left ctrl true" do
        @subject.left_ctrl = true
        expect(@subject.ctrl).must_equal true
      end

      it "should be true when right ctrl true" do
        @subject.left_ctrl = true
        expect(@subject.ctrl).must_equal true
      end

      it "should be true when left and right ctrl true" do
        @subject.left_ctrl = true
        @subject.right_ctrl = true
        expect(@subject.ctrl).must_equal true
      end
    end

    describe "#shift" do
      it "should be false" do
        expect(@subject.shift).must_equal false
      end

      it "should be true when left shift true" do
        @subject.left_shift = true
        expect(@subject.shift).must_equal true
      end

      it "should be true when right shift true" do
        @subject.left_shift = true
        expect(@subject.shift).must_equal true
      end

      it "should be true when left and right shift true" do
        @subject.left_shift = true
        @subject.right_shift = true
        expect(@subject.shift).must_equal true
      end
    end

    describe "#alt" do
      it "should be false" do
        expect(@subject.alt).must_equal false
      end

      it "should be true when left alt true" do
        @subject.left_alt = true
        expect(@subject.alt).must_equal true
      end

      it "should be true when right alt true" do
        @subject.left_alt = true
        expect(@subject.alt).must_equal true
      end

      it "should be true when left and right alt true" do
        @subject.left_alt = true
        @subject.right_alt = true
        expect(@subject.alt).must_equal true
      end
    end

    describe "#super" do
      it "should be false" do
        expect(@subject.super).must_equal false
      end

      it "should be true when left super true" do
        @subject.left_super = true
        expect(@subject.super).must_equal true
      end

      it "should be true when right super true" do
        @subject.left_super = true
        expect(@subject.super).must_equal true
      end

      it "should be true when left and right super true" do
        @subject.left_super = true
        @subject.right_super = true
        expect(@subject.super).must_equal true
      end
    end
  end
end
