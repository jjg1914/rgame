require "dungeon"
require "fileutils"
require "tmpdir"

class RenderTest < MiniTest::Test
  def test_colors
    klass = Class.new(Dungeon::Common::RootEntity)
    klass.window.size = [ 128, 128 ]
    klass.window.title = "colors"
    klass.window.mode = "software"
    klass.on :draw do
      ctx.color = 0x888888
      ctx.clear

      ctx.color = 0xFF0000
      ctx.fill_rect 0, 0, 32, 32
      ctx.color = 0xffff00
      ctx.fill_rect 32, 0, 32, 32
      ctx.color = 0xff7f00
      ctx.fill_rect 64, 0, 32, 32
      ctx.color = 0x007fff
      ctx.fill_rect 96, 0, 32, 32

      ctx.color = 0x7fff00
      ctx.fill_rect 0, 32, 32, 32
      ctx.color = 0x00ff00
      ctx.fill_rect 32, 32, 32, 32
      ctx.color = 0x00ffff
      ctx.fill_rect 64, 32, 32, 32
      ctx.color = 0x7f00ff
      ctx.fill_rect 96, 32, 32, 32

      ctx.color = 0xff00ff
      ctx.fill_rect 0, 64, 32, 32
      ctx.color = 0x00ff7f
      ctx.fill_rect 32, 64, 32, 32
      ctx.color = 0x0000ff
      ctx.fill_rect 64, 64, 32, 32
      ctx.color = 0xff007f
      ctx.fill_rect 96, 64, 32, 32

      ctx.color = 0xffffff
      ctx.fill_rect 0, 96, 32, 32
      ctx.color = 0xababab
      ctx.fill_rect 32, 96, 32, 32
      ctx.color = 0x545454
      ctx.fill_rect 64, 96, 32, 32
      ctx.color = 0x000000
      ctx.fill_rect 96, 96, 32, 32
    end

    Dir.mktmpdir do |dir|
      FileUtils.cd(dir) do
        klass.run!
        base = File.join(File.dirname(__FILE__), "bitmaps/colors.png")
        diff = %x[compare -metric AE colors.bmp #{base} out.bmp 2>&1]
        assert_equal(0, diff.to_f)
      end
    end
  end
end
