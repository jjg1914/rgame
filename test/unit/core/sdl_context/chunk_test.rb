require "rgame/core/sdl_context/chunk" 

describe RGame::Core::SDLContext::Chunk do
  before do
    @fake_chunk = FFI::MemoryPointer.new :int, 1
    @subject = RGame::Core::SDLContext::Chunk.new @fake_chunk
  end

  after do
    @fake_chunk.free
  end

  describe "#free" do
    it "should free chunk" do
      mock = MiniTest::Mock.new
      mock.expect :call, nil, [ @fake_chunk ]

      RGame::Core::SDL2Mixer.stub(:Mix_FreeChunk, lambda do |chunk|
        mock.call chunk
      end) do
        @subject.free
        expect(@subject.chunk).must_be :nil?
      end

      mock.verify
    end
  end
end
