require "rgame/core/sdl_context/texture_cache" 

describe RGame::Core::SDLContext::TextureCache do
  before do
    @old_assets_path = RGame::Core::Env.assets_path
    RGame::Core::Env.assets_path = File.expand_path("../../../integration",
                                                    File.dirname(__FILE__))

    unless RGame::Core::SDL2.SDL_Init(0).zero?
      raise RGame::Core::SDL2.SDL_GetError
    end

    format = RGame::Core::SDL2::SDL_PIXELFORMAT_ARGB8888
    @sdl_surface = RGame::Core::SDL2.SDL_CreateRGBSurfaceWithFormat(0, 123, 456,
                                                                    32, format)
    @sdl_renderer = RGame::Core::SDL2.SDL_CreateSoftwareRenderer @sdl_surface
    @subject = RGame::Core::SDLContext::TextureCache.new @sdl_renderer
  end

  after do
    RGame::Core::SDL2.SDL_FreeSurface @sdl_surface
    RGame::Core::SDL2.SDL_DestroyRenderer @sdl_renderer

    RGame::Core::Env.assets_path = @old_assets_path
  end

  describe "#_impl_load" do
    it "should load texture" do
      expect(@subject["colors"])
        .must_be_kind_of RGame::Core::SDLContext::Texture
    end

    it "should set texture" do
      expect(@subject["colors"].texture).wont_be :null?
    end

    it "should set name" do
      expect(@subject["colors"].name).must_equal "colors"
    end

    it "should set path" do
      expect(@subject["colors"].path)
        .must_equal File.join(RGame::Core::Env.assets_path, "images/colors.png")
    end
  end
end
