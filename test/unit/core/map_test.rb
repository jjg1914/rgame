require "dungeon/core/map"

describe Dungeon::Core::Map do
  describe ".load_file" do
    describe "with tiled" do
      it "should load json" do
        path = File.join(File.dirname(__FILE__), "map_test_tiled.json")
        map = Dungeon::Core::Map.load_file(path)

        expect(map.name).must_equal "map_test_tiled"
        expect(map.width).must_equal 160
        expect(map.height).must_equal 144
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
        expect(map.background).must_equal 0x202020
      end
    end
  end
end
