require "rgame/core/sdl"

describe RGame::Core::SDL2 do
  describe RGame::Core::SDL2::SDLColor do
    describe "#assign" do
      it "should assign all colors" do
        subject = RGame::Core::SDL2::SDLColor.new
        subject[:r] = 0
        subject[:g] = 0
        subject[:b] = 0
        subject[:a] = 0

        subject.assign 1, 2, 3, 4
        expect([
          subject[:r],
          subject[:g],
          subject[:b],
          subject[:a],
        ]).must_equal([ 1, 2, 3, 4 ])
      end
    end
  end
end
