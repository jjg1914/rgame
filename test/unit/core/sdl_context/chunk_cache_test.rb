require "rgame/core/sdl_context/chunk_cache" 

describe RGame::Core::SDLContext::ChunkCache do
  before do
    @old_assets_path = RGame::Core::Env.assets_path
    RGame::Core::Env.assets_path = File.expand_path("../../../integration",
                                                    File.dirname(__FILE__))

    @subject = RGame::Core::SDLContext::ChunkCache.new
  end

  after do

    RGame::Core::Env.assets_path = @old_assets_path
  end

  describe "#_impl_load" do
    it "should load texture" do
      expect(@subject["chunk"])
        .must_be_kind_of RGame::Core::SDLContext::Chunk
    end

    it "should set texture" do
      mock = MiniTest::Mock.new
      mock.expect :call, nil, [ FFI::Pointer, 1 ]
      
      RGame::Core::SDL2Mixer.stub(:Mix_LoadWAV_RW, lambda do |a,b|
        mock.call a, b
        "-fake-chunk-"
      end) do
        expect(@subject["chunk"].chunk).must_equal "-fake-chunk-"
      end

      mock.verify
    end

    it "should set name" do
      expect(@subject["chunk"].name).must_equal "chunk"
    end

    it "should set path" do
      expect(@subject["chunk"].path)
        .must_equal File.join(RGame::Core::Env.assets_path, "sounds/chunk.wav")
    end
  end
end
