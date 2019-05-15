require "dungeon/core/collision"

describe Dungeon::Core::Collision do
  describe ".bounds_for" do
    it "should return bounds" do
      o = Object.new
      class << o
        def x; 1; end
        def y; 2; end
        def width; 3; end
        def height; 4; end
      end

      expect(Dungeon::Core::Collision.bounds_for(o)).must_equal({
        "left" => 1,
        "top" => 2,
        "right" => 3,
        "bottom" => 5,
      })
    end
  end
end
