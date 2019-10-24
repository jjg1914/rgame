require "rgame/core/env" 
require "rgame/core/sdl_context/renderer" 

describe RGame::Core::SDLContext::Renderer do
  before do
    @old_assets_path = RGame::Core::Env.assets_path
    RGame::Core::Env.assets_path = File.expand_path("../../../integration",
                                                    File.dirname(__FILE__))

    unless RGame::Core::SDL2.SDL_Init(0).zero?
      raise RGame::Core::SDL2.SDL_GetError
    end

    format = RGame::Core::SDL2::SDL_PIXELFORMAT_ARGB8888
    @sdl_surface = RGame::Core::SDL2.SDL_CreateRGBSurfaceWithFormat(0, 32, 32,
                                                                    32, format)
    @sdl_renderer = RGame::Core::SDL2.SDL_CreateSoftwareRenderer @sdl_surface
    @subject = RGame::Core::SDLContext::Renderer.new @sdl_renderer

    @mem_ints = 8.times.map { FFI::MemoryPointer.new(:int, 1) }
    @mem_floats = 8.times.map { FFI::MemoryPointer.new(:float, 1) }
  end

  after do
    @mem_ints.each { |e| e.free }
    @mem_floats.each { |e| e.free }

    RGame::Core::SDL2.SDL_FreeSurface @sdl_surface
    RGame::Core::SDL2.SDL_DestroyRenderer @sdl_renderer

    RGame::Core::Env.assets_path = @old_assets_path
  end

  describe "#color=" do
    it "should set color" do
      @subject.color = 0x123456
      RGame::Core::SDL2.SDL_GetRenderDrawColor @sdl_renderer,
                                               @mem_ints[0],
                                               @mem_ints[1],
                                               @mem_ints[2],
                                               @mem_ints[3]
      expect([
        @mem_ints[0].get(:int, 0),
        @mem_ints[1].get(:int, 0),
        @mem_ints[2].get(:int, 0),
        @mem_ints[3].get(:int, 0),
      ]).must_equal([ 0x12, 0x34, 0x56, 0xFF ])
    end
  end

  describe "#alpha=" do
    it "should set alpha" do
      @subject.alpha = 0xAB
      RGame::Core::SDL2.SDL_GetRenderDrawColor @sdl_renderer,
                                               @mem_ints[0],
                                               @mem_ints[1],
                                               @mem_ints[2],
                                               @mem_ints[3]
      expect([
        @mem_ints[0].get(:int, 0),
        @mem_ints[1].get(:int, 0),
        @mem_ints[2].get(:int, 0),
        @mem_ints[3].get(:int, 0),
      ]).must_equal([ 0x00, 0x00, 0x00, 0xAB ])
    end
  end

  describe "#scale=" do
    it "should set scale" do
      @subject.scale = [ 1.25, 2.125, 3.5 ]
      RGame::Core::SDL2.SDL_RenderGetScale @sdl_renderer,
                                           @mem_floats[0],
                                           @mem_floats[1]

      expect([
        @mem_floats[0].get(:float, 0),
        @mem_floats[1].get(:float, 0),
      ]).must_equal([ 1.25, 2.125 ])
    end

    it "should set single scale" do
      @subject.scale = [ 1.25 ]
      RGame::Core::SDL2.SDL_RenderGetScale @sdl_renderer,
                                           @mem_floats[0],
                                           @mem_floats[1]

      expect([
        @mem_floats[0].get(:float, 0),
        @mem_floats[1].get(:float, 0),
      ]).must_equal([ 1.25, 1.25 ])
    end

    it "should set single scale" do
      RGame::Core::SDL2.SDL_RenderSetScale @sdl_renderer, 2.0, 2.0
      @subject.instance_variable_set :@scale, nil
      @subject.scale = []
      RGame::Core::SDL2.SDL_RenderGetScale @sdl_renderer,
                                           @mem_floats[0],
                                           @mem_floats[1]

      expect([
        @mem_floats[0].get(:float, 0),
        @mem_floats[1].get(:float, 0),
      ]).must_equal([ 1.0, 1.0 ])
    end
  end

  describe "#scale_quality=" do
    it "should set nearest scale quality" do
      @subject.scale_quality = "nearest"
      hint = RGame::Core::SDL2.SDL_GetHint(
        RGame::Core::SDL2::SDL_HINT_RENDER_SCALE_QUALITY)
      expect(hint).must_equal "0"
    end

    it "should set linear scale quality" do
      @subject.scale_quality = "  linear  "
      hint = RGame::Core::SDL2.SDL_GetHint(
        RGame::Core::SDL2::SDL_HINT_RENDER_SCALE_QUALITY)
      expect(hint).must_equal "1"
    end

    it "should set best scale quality" do
      @subject.scale_quality = "BEST"
      hint = RGame::Core::SDL2.SDL_GetHint(
        RGame::Core::SDL2::SDL_HINT_RENDER_SCALE_QUALITY)
      expect(hint).must_equal "2"
    end

    it "should set invalid scale quality" do
      @subject.scale_quality = "foo"
      hint = RGame::Core::SDL2.SDL_GetHint(
        RGame::Core::SDL2::SDL_HINT_RENDER_SCALE_QUALITY)
      expect(hint).must_equal "0"
    end
  end

  describe "#source=" do
  end

  describe "#target=" do
  end

  describe "#stroke_rect" do
    before do
      @subject.clear
      RGame::Core::SDL2.SDL_SetRenderDrawColor @sdl_renderer, 0xFF, 0x0, 0x0, 0xFF
    end

    it "should stroke rect" do
      @subject.stroke_rect 0, 0, 32, 32
      pixel_data = 32.times.map do |j|
        32.times.map do |i|
          @sdl_surface[:pixels].get(:uint32, (j * 128) + (i * 4))
        end
      end
      expect(pixel_data.each_with_index.all? do |e,i|
        e.each_with_index.all? do |f,j|
          if i == 0 or i == 31 or j == 0 or j == 31
            f == 0xFF0000FF
          else
            f == 0x000000FF
          end
        end
      end).must_equal true
    end
  end

  describe "#fill_rect" do
    before do
      @subject.clear
      RGame::Core::SDL2.SDL_SetRenderDrawColor @sdl_renderer, 0xFF, 0x0, 0x0, 0xFF
    end

    it "should fill rect" do
      @subject.fill_rect 0, 0, 32, 32
      pixel_data = 32.times.map do |j|
        32.times.map do |i|
          @sdl_surface[:pixels].get(:uint32, (j * 128) + (i * 4))
        end
      end
      expect(pixel_data.all? do |e|
        e.all? { |f| f == 0xFF0000FF }
      end).must_equal true
    end
  end
end
