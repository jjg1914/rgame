require "dungeon/core/sprite"

describe Dungeon::Core::Sprite do
  describe ".load" do
    describe "with tags" do
      it "should load json" do
        path = File.join(File.dirname(__FILE__), "data/sprite_test")
        sprite = Dungeon::Core::Sprite.load(path)

        expect(sprite.name).must_equal "sprite_test"
        expect(sprite.path).must_equal "%s.json" % path
        expect(sprite.image).must_equal "sprite_text"
        expect(sprite.width).must_equal 16
        expect(sprite.height).must_equal 16
        expect(sprite.frames).must_equal(18.times.map do |i|
          Dungeon::Core::Sprite::FrameData.new(0 + (16 * i), 0, 16, 16)
        end)
        expect(sprite.tags).must_equal({
          "fow" => Dungeon::Core::Sprite::FrameTag.new(
            [ 0, 1, 2, 3, 4, 5 ],
            ([ 100 ] * 6),
          ),
          "back" => Dungeon::Core::Sprite::FrameTag.new(
            [ 11, 10, 9, 8, 7, 6 ],
            ([ 100 ] * 6),
          ),
          "pong" => Dungeon::Core::Sprite::FrameTag.new(
            [ 12, 13, 14, 15, 16, 17, 16, 15, 14, 13 ],
            ([ 100 ] * 10),
          ),
          "blank" => Dungeon::Core::Sprite::FrameTag.new(
            18.times.map.to_a,
            ([ 100 ] * 18),
          ),
        })
      end
    end

    describe "without tags" do
      it "should load json" do
        path = File.join(File.dirname(__FILE__), "data/sprite_no_tag_test")
        sprite = Dungeon::Core::Sprite.load(path)

        expect(sprite.name).must_equal "sprite_no_tag_test"
        expect(sprite.path).must_equal "%s.json" % path
        expect(sprite.image).must_equal "sprite_text"
        expect(sprite.width).must_equal 16
        expect(sprite.height).must_equal 16
        expect(sprite.frames).must_equal(18.times.map do |i|
          Dungeon::Core::Sprite::FrameData.new(0 + (16 * i), 0, 16, 16)
        end)
        expect(sprite.tags).must_equal({
          "" => Dungeon::Core::Sprite::FrameTag.new(
            18.times.map.to_a,
            ([ 100 ] * 18),
          ),
        })
      end
    end
  end

  describe "#next_frame_key" do
    before do
      @subject= Dungeon::Core::Sprite.new "test", [
        Dungeon::Core::Sprite::FrameData.new(0, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(16, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(32, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(48, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(64, 0, 16, 16),
      ], {
        "foo" => Dungeon::Core::Sprite::FrameTag.new(
          [ 0, 1, 2, 3, 4 ],
          [ 10, 20, 30, 40, 50 ],
        ),
      }
    end

    it "should return current frame and key" do
      expect(@subject.next_frame_key("foo", 1, 5 )).must_equal([ 1, 5 ])
    end

    it "should return next frame and key" do
      expect(@subject.next_frame_key("foo", 1, 30 )).must_equal([ 2, 10 ])
    end

    it "should return skip frames and keys" do
      expect(@subject.next_frame_key("foo", 1, 110 )).must_equal([ 4, 20 ])
    end

    it "should raise error" do
      expect(proc do
        @subject.next_frame_key("bar", 1, 30)
      end).must_raise IndexError
    end
  end

  describe "#at" do
    before do
      @subject= Dungeon::Core::Sprite.new "test", [
        Dungeon::Core::Sprite::FrameData.new(0, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(16, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(32, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(48, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(64, 0, 16, 16),
      ], {
        "foo" => Dungeon::Core::Sprite::FrameTag.new(
          [ 0, 1, 2, 3, 4 ],
          [ 10, 20, 30, 40, 50 ],
        ),
      }
    end

    it "should return dimensions" do
      expect(@subject.at("foo", 1)).must_equal([ 16, 0, 16, 16 ])
    end

    it "should raise error" do
      expect(proc do
        @subject.at("bar", 2)
      end).must_raise IndexError
    end
  end

  describe "#default_tag" do
    before do
      @subject= Dungeon::Core::Sprite.new "test", [
        Dungeon::Core::Sprite::FrameData.new(0, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(16, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(32, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(48, 0, 16, 16),
        Dungeon::Core::Sprite::FrameData.new(64, 0, 16, 16),
      ], {
        "foo" => Dungeon::Core::Sprite::FrameTag.new(
          [ 1, 2 ],
          [ 10, 20 ],
        ),
        "bar" => Dungeon::Core::Sprite::FrameTag.new(
          [ 0, 3 ],
          [ 10, 20 ],
        ),
        "baz" => Dungeon::Core::Sprite::FrameTag.new(
          [ 4 ],
          [ 20 ],
        ),
      }
    end

    it "should return default tag" do
      expect(@subject.default_tag).must_equal "bar"
    end
  end
end
