require "rgame/core/sdl_context/texture" 

describe RGame::Core::SDLContext::Texture do
  before do
    unless RGame::Core::SDL2.SDL_Init(0).zero?
      raise RGame::Core::SDL2.SDL_GetError
    end

    format = RGame::Core::SDL2::SDL_PIXELFORMAT_ARGB8888
    flags = RGame::Core::SDL2::SDL_TEXTUREACCESS_TARGET
    @sdl_surface = RGame::Core::SDL2.SDL_CreateRGBSurfaceWithFormat(0, 123, 456,
                                                                    32, format)
    @sdl_renderer = RGame::Core::SDL2.SDL_CreateSoftwareRenderer @sdl_surface
    @sdl_texture = RGame::Core::SDL2.SDL_CreateTexture(@sdl_renderer, format,
                                                  flags, 123, 456)
    @subject = RGame::Core::SDLContext::Texture.new @sdl_texture
  end

  after do
    RGame::Core::SDL2.SDL_DestroyTexture @sdl_texture
    RGame::Core::SDL2.SDL_DestroyRenderer @sdl_renderer
    RGame::Core::SDL2.SDL_FreeSurface @sdl_surface
  end

  describe "#width" do
    it "should return texture width" do
      expect(@subject.width).must_equal 123
    end
  end

  describe "#height" do
    it "should return texture height" do
      expect(@subject.height).must_equal 456
    end
  end

  describe "#free" do
    it "should free texture" do
      mock = MiniTest::Mock.new
      mock.expect :call, nil, [ @sdl_texture ]

      RGame::Core::SDL2.stub(:SDL_DestroyTexture , lambda do |txt|
        mock.call txt
      end) do
        @subject.free
        expect(@subject.texture).must_be :nil?
      end

      mock.verify
    end
  end

  describe "#texture_blend_mode" do
    describe "with none" do
      before do
        mode = RGame::Core::SDL2::SDL_BLENDMODE_NONE
        RGame::Core::SDL2.SDL_SetTextureBlendMode(@sdl_texture, mode)
      end

      it "should return blend mode string" do
        expect(@subject.texture_blend_mode).must_equal "none"
      end
    end

    describe "with blend" do
      before do
        mode = RGame::Core::SDL2::SDL_BLENDMODE_BLEND
        RGame::Core::SDL2.SDL_SetTextureBlendMode(@sdl_texture, mode)
      end

      it "should return blend mode string" do
        expect(@subject.texture_blend_mode).must_equal "blend"
      end
    end

    describe "with add" do
      before do
        mode = RGame::Core::SDL2::SDL_BLENDMODE_ADD
        RGame::Core::SDL2.SDL_SetTextureBlendMode(@sdl_texture, mode)
      end

      it "should return blend mode string" do
        expect(@subject.texture_blend_mode).must_equal "add"
      end
    end

    describe "with mod" do
      before do
        mode = RGame::Core::SDL2::SDL_BLENDMODE_MOD
        RGame::Core::SDL2.SDL_SetTextureBlendMode(@sdl_texture, mode)
      end

      it "should return blend mode string" do
        expect(@subject.texture_blend_mode).must_equal "mod"
      end
    end

    describe "with invalid" do
      it "should return blend mode string" do
        RGame::Core::SDL2.stub(:SDL_GetTextureBlendMode, lambda do |txt,mem|
          mem.write :int, RGame::Core::SDL2::SDL_BLENDMODE_INVALID
        end) do
          expect(@subject.texture_blend_mode).must_equal "invalid"
        end
      end
    end
  end

  describe "#texture_blend_mode=" do
    before do
      @mem_int = FFI::MemoryPointer.new(:int, 1)
    end

    after do
      @mem_int.free unless @mem_int.nil? or @mem_int.null?
    end

    describe "with none" do
      it "should return set blend mode" do
        @subject.texture_blend_mode = "none"
        RGame::Core::SDL2.SDL_GetTextureBlendMode @sdl_texture, @mem_int
        expect(@mem_int.get(:int, 0))
          .must_equal RGame::Core::SDL2::SDL_BLENDMODE_NONE
      end
    end

    describe "with blend" do
      it "should return set blend mode" do
        @subject.texture_blend_mode = "blend"
        RGame::Core::SDL2.SDL_GetTextureBlendMode @sdl_texture, @mem_int
        expect(@mem_int.get(:int, 0))
          .must_equal RGame::Core::SDL2::SDL_BLENDMODE_BLEND
      end
    end

    describe "with add" do
      it "should return set blend mode" do
        @subject.texture_blend_mode = "add"
        RGame::Core::SDL2.SDL_GetTextureBlendMode @sdl_texture, @mem_int
        expect(@mem_int.get(:int, 0))
          .must_equal RGame::Core::SDL2::SDL_BLENDMODE_ADD
      end
    end

    describe "with mod" do
      it "should return set blend mode" do
        @subject.texture_blend_mode = "mod"
        RGame::Core::SDL2.SDL_GetTextureBlendMode @sdl_texture, @mem_int
        expect(@mem_int.get(:int, 0))
          .must_equal RGame::Core::SDL2::SDL_BLENDMODE_MOD
      end
    end

    describe "with invalid" do
      it "should return set blend mode" do
        mock = MiniTest::Mock.new
        mock.expect :call, nil, [ @sdl_texture,
                                  RGame::Core::SDL2::SDL_BLENDMODE_INVALID ]
        RGame::Core::SDL2.stub(:SDL_SetTextureBlendMode, lambda do |txt, mode|
          mock.call txt, mode
        end) do
          @subject.texture_blend_mode = "foo"
        end

        mock.verify
      end
    end
  end
end
