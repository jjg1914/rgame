require "rgame/core/env"

describe RGame::Core::Env do
  describe "#enable_software_mode" do
    stash_env "ENABLE_HEADLESS_MODE"

    describe "when ENABLE_HEADLESS_MODE is nil" do
      before do
        ENV.delete "ENABLE_HEADLESS_MODE"
      end

      it "should return false" do
        expect(RGame::Core::Env.enable_software_mode).must_equal false
      end
    end

    describe "when ENABLE_HEADLESS_MODE is zero" do
      before do
        ENV["ENABLE_HEADLESS_MODE"] = "0"
      end

      it "should return false" do
        expect(RGame::Core::Env.enable_software_mode).must_equal false
      end
    end

    describe "when ENABLE_HEADLESS_MODE is non-zero" do
      before do
        ENV["ENABLE_HEADLESS_MODE"] = "1"
      end

      it "should return true" do
        expect(RGame::Core::Env.enable_software_mode).must_equal true
      end
    end

    describe "when ENABLE_HEADLESS_MODE is non-int" do
      before do
        ENV["ENABLE_HEADLESS_MODE"] = "x"
      end

      it "should return false" do
        expect(RGame::Core::Env.enable_software_mode).must_equal false
      end
    end
  end

  describe "#enable_mmap_mode" do
    stash_env "ENABLE_MMAP_MODE"

    describe "when ENABLE_MMAP_MODE is nil" do
      before do
        ENV.delete "ENABLE_MMAP_MODE"
      end

      it "should return false" do
        expect(RGame::Core::Env.enable_mmap_mode).must_equal false
      end
    end

    describe "when ENABLE_MMAP_MODE is zero" do
      before do
        ENV["ENABLE_MMAP_MODE"] = "0"
      end

      it "should return false" do
        expect(RGame::Core::Env.enable_mmap_mode).must_equal false
      end
    end

    describe "when ENABLE_MMAP_MODE is non-zero" do
      before do
        ENV["ENABLE_MMAP_MODE"] = "1"
      end

      it "should return true" do
        expect(RGame::Core::Env.enable_mmap_mode).must_equal true
      end
    end

    describe "when ENABLE_MMAP_MODE is non-int" do
      before do
        ENV["ENABLE_MMAP_MODE"] = "x"
      end

      it "should return false" do
        expect(RGame::Core::Env.enable_mmap_mode).must_equal false
      end
    end
  end

  describe "#mmap_file" do
    stash_env "MMAP_FILE"

    it "should return MMAP_FILE" do
      ENV["MMAP_FILE"] = "_value_"
      expect(RGame::Core::Env.mmap_file).must_equal "_value_"
    end
  end

  describe "#mmap_file=" do
    stash_env "MMAP_FILE"

    it "should assign MMAP_FILE" do
      ENV["MMAP_FILE"] = "_value_"
      RGame::Core::Env.mmap_file = "_value_2_"
      expect(ENV["MMAP_FILE"]).must_equal "_value_2_"
    end
  end

  describe "#font_path" do
    stash_env "FONT_PATH"

    describe "with FONT_PATH set" do
      before { ENV["FONT_PATH"] = "/path/to/fonts" }

      it "should return FONT_PATH" do
        expect(RGame::Core::Env.font_path).must_equal("/path/to/fonts")
      end
    end

    describe "without FONT_PATH set" do
      before { ENV.delete "FONT_PATH" }

      describe "when windows" do
        it "should return font_path"
      end

      describe "when macos" do
        it "should return font_path"
      end

      describe "when other os" do
        it "should return font_path"
      end
    end
  end

  describe "#font_path=" do
    stash_env "FONT_PATH"

    it "should assign FONT_PATH" do
      ENV["FONT_PATH"] = "_value_"
      RGame::Core::Env.font_path = "_value_2_"
      expect(ENV["FONT_PATH"]).must_equal "_value_2_"
    end
  end

  describe "#sound_path" do
    stash_env "SOUND_PATH"

    describe "with SOUND_PATH set" do
      before { ENV["SOUND_PATH"] = "/path/to/sounds" }

      it "should return SOUND_PATH" do
        expect(RGame::Core::Env.sound_path).must_equal("/path/to/sounds")
      end
    end

    describe "without SOUND_PATH set" do
      it "should return sound_path" do
        RGame::Core::Env.stub(:assets_path, lambda { "/assets/path" }) do
          expect(RGame::Core::Env.sound_path).must_equal("/assets/path/sounds")
        end
      end
    end
  end

  describe "#sound_path=" do
    stash_env "SOUND_PATH"

    it "should assign SOUND_PATH" do
      ENV["SOUND_PATH"] = "_value_"
      RGame::Core::Env.sound_path = "_value_2_"
      expect(ENV["SOUND_PATH"]).must_equal "_value_2_"
    end
  end

  describe "#image_path" do
    stash_env "IMAGE_PATH"

    describe "with IMAGE_PATH set" do
      before { ENV["IMAGE_PATH"] = "/path/to/images" }

      it "should return IMAGE_PATH" do
        expect(RGame::Core::Env.image_path).must_equal("/path/to/images")
      end
    end

    describe "without IMAGE_PATH set" do
      it "should return image_path" do
        RGame::Core::Env.stub(:assets_path, lambda { "/assets/path" }) do
          expect(RGame::Core::Env.image_path).must_equal("/assets/path/images:/assets/path/sprites:/assets/path/tilesets")
        end
      end
    end
  end

  describe "#image_path=" do
    stash_env "IMAGE_PATH"

    it "should assign IMAGE_PATH" do
      ENV["IMAGE_PATH"] = "_value_"
      RGame::Core::Env.image_path = "_value_2_"
      expect(ENV["IMAGE_PATH"]).must_equal "_value_2_"
    end
  end

  describe "#sprite_path" do
    stash_env "SPRITE_PATH"

    describe "with SPRITE_PATH set" do
      before { ENV["SPRITE_PATH"] = "/path/to/sprites" }

      it "should return SPRITE_PATH" do
        expect(RGame::Core::Env.sprite_path).must_equal("/path/to/sprites")
      end
    end

    describe "without SPRITE_PATH set" do
      it "should return sprite_path" do
        RGame::Core::Env.stub(:assets_path, lambda { "/assets/path" }) do
          expect(RGame::Core::Env.sprite_path).must_equal("/assets/path/sprites")
        end
      end
    end
  end

  describe "#sprite_path=" do
    stash_env "SPRITE_PATH"

    it "should assign SPRITE_PATH" do
      ENV["SPRITE_PATH"] = "_value_"
      RGame::Core::Env.sprite_path = "_value_2_"
      expect(ENV["SPRITE_PATH"]).must_equal "_value_2_"
    end
  end

  describe "#tileset_path" do
    stash_env "TILESET_PATH"

    describe "with TILESET_PATH set" do
      before { ENV["TILESET_PATH"] = "/path/to/tilesets" }

      it "should return TILESET_PATH" do
        expect(RGame::Core::Env.tileset_path).must_equal("/path/to/tilesets")
      end
    end

    describe "without TILESET_PATH set" do
      it "should return tileset_path" do
        RGame::Core::Env.stub(:assets_path, lambda { "/assets/path" }) do
          expect(RGame::Core::Env.tileset_path).must_equal("/assets/path/tilesets")
        end
      end
    end
  end

  describe "#tileset_path=" do
    stash_env "TILESET_PATH"

    it "should assign TILESET_PATH" do
      ENV["TILESET_PATH"] = "_value_"
      RGame::Core::Env.tileset_path = "_value_2_"
      expect(ENV["TILESET_PATH"]).must_equal "_value_2_"
    end
  end

  describe "#map_path" do
    stash_env "MAP_PATH"

    describe "with MAP_PATH set" do
      before { ENV["MAP_PATH"] = "/path/to/maps" }

      it "should return MAP_PATH" do
        expect(RGame::Core::Env.map_path).must_equal("/path/to/maps")
      end
    end

    describe "without MAP_PATH set" do
      it "should return map_path" do
        RGame::Core::Env.stub(:assets_path, lambda { "/assets/path" }) do
          expect(RGame::Core::Env.map_path).must_equal("/assets/path/maps")
        end
      end
    end
  end

  describe "#map_path=" do
    stash_env "MAP_PATH"

    it "should assign MAP_PATH" do
      ENV["MAP_PATH"] = "_value_"
      RGame::Core::Env.map_path = "_value_2_"
      expect(ENV["MAP_PATH"]).must_equal "_value_2_"
    end
  end

  describe "#assets_path" do
    stash_env "ASSETS_PATH"

    describe "with ASSETS_PATH set" do
      before { ENV["ASSETS_PATH"] = "/path/to/assets" }
      
      it "should return assets_path" do
        expect(RGame::Core::Env.assets_path).must_equal("/path/to/assets")
      end
    end

    describe "without ASSETS_PATH set" do
      before do
        ENV.delete "ASSETS_PATH"
        @_old0 = $0
        $0 = "/some/bin/path"
      end

      after do
        $0 = @_old0
      end

      it "should return assets_path" do
        raise if $0 != "/some/bin/path"
        expect(RGame::Core::Env.assets_path).must_equal("/some/bin/assets")
      end
    end
  end

  describe "#assets_path=" do
    stash_env "ASSETS_PATH"

    it "should assign ASSETS_PATH" do
      ENV["ASSETS_PATH"] = "_value_"
      RGame::Core::Env.assets_path = "_value_2_"
      expect(ENV["ASSETS_PATH"]).must_equal "_value_2_"
    end
  end
end
