require "dungeon/core/map"

describe Dungeon::Core::Map do
  describe ".load" do
    describe "with tiled" do
      it "should load json" do
        path = File.join(File.dirname(__FILE__), "data/map_test_tiled")
        map = Dungeon::Core::Map.load(path)

        expect(map.name).must_equal "map_test_tiled"
        expect(map.path).must_equal "%s.json" % path
        expect(map.width).must_equal 160
        expect(map.height).must_equal 144
        expect(map.background).must_equal 0x202020
        expect(map.entities).must_equal [
          {
            "type" => "dungeon::common::imagelayer",
            "image" => "stage-bg",
          },
          {
            "type" => "dungeon::common::tilelayer",
            "tileset" => "tileset",
            "data" => [
              [ 18, 16, 16, 16, 16, 16, 16, 16, 16, 19 ],
              [ 33, 48, 48, 48, 48, 48, 48, 48, 48, 32 ],
              [ 20, 0, 2, 0, 0, 0, 0, 0, 0, 32 ],
              [ 48, 0, 0, 0, 0, 0, 1, 0, 0, 32 ],
              [ 0, 0, 0, 0, 4, 0, 0, 2, 0, 32 ],
              [ 2, 0, 1, 0, 0, 0, 0, 0, 0, 32 ],
              [ 36, 0, 0, 0, 0, 0, 0, 0, 0, 32 ],
              [ 33, 0, 0, 0, 0, 0, 0, 3, 0, 32 ],
              [ 34, 17, 17, 17, 17, 17, 17, 17, 17, 35 ],
            ],
          },
          {
            "type" => "block",
            "x" => 32,
            "y" => 152,
            "width" => 16,
            "height" => 8,
            "foo" => 1,
            "bar" => 1.0,
            "bool1" => true,
            "bool2" => false,
            "str" => "123",
            "str2" => "123",
          },
          {
            "type" => "block",
            "x" => 48,
            "y" => 152,
            "width" => 16,
            "height" => 8,
          },
          {
            "type" => "block",
            "x" => 64,
            "y" => 152,
            "width" => 16,
            "height" => 8,
          },
        ]
      end
    end

    describe "with dungeon" do
      it "should load json" do
        path = File.join(File.dirname(__FILE__), "data/map_test_dungeon")
        map = Dungeon::Core::Map.load(path)

        expect(map.name).must_equal "map_test_dungeon"
        expect(map.path).must_equal "%s.json" % path
        expect(map.width).must_equal 272
        expect(map.height).must_equal 288
        expect(map.background).must_equal 0x2800BA
        expect(map.entities).must_equal [
          {
            "type" => "dungeon::common::imagelayer",
            "image" => "stage-bg",
          },
          {
            "type" => "block",
            "x" => 24,
            "y" => 88,
            "sprite_tag" => "red",
          },
        ]
      end
    end

    describe "with invalid" do
      it "should load json" do
        path = File.join(File.dirname(__FILE__), "data/map_test_invalid")
        expect(proc do
          Dungeon::Core::Map.load(path)
        end).must_raise
      end
    end
  end
end
