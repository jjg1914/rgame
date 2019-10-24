require "rgame"
require "fileutils"
require "tmpdir"

class RenderTest < MiniTest::Test
  def test_software_colors
    klass = Class.new(RGame::Common::RootEntity)
    klass.window.size = [ 128, 128 ]
    klass.window.mode = "software"
    klass.on :draw do
      RenderTest._draw_colors ctx
      ctx.events.quit!
    end

    klass.on :end do
      buffer = ctx.read_bytes
      File.write("colors.bin", buffer.bytes.each_slice(4).map do |e|
        e.tap do
          e.push(e.shift)
          e[0], e[2] = [ e[2], e[0] ]
        end
      end.flatten.map { |e| e.chr }.join)
    end

    Dir.mktmpdir do |dir|
      FileUtils.cd(dir) do
        klass.run!
        base = File.join(File.dirname(__FILE__), "images/colors.png")
        %x[convert -size 128x128 -depth 8 RGBA:colors.bin tmp.png]
        assert($?.success?)
        diff = %x[compare -metric AE tmp.png #{base} out.png 2>&1]
        assert($?.exitstatus < 2)
        assert_equal(0, diff.to_f)
      end
    end
  end

  def test_mmap_colors
    RGame::Core::Env.mmap_file = "colors.bin"

    klass = Class.new(RGame::Common::RootEntity)
    klass.window.size = [ 128, 128 ]
    klass.window.mode = "mmap"
    klass.on :draw do
      RenderTest._draw_colors ctx
      ctx.events.quit!
    end

    klass.on :end do
      fd = RGame::Core::Internal.shm_open "colors.bin", Fcntl::O_RDWR | Fcntl::O_CREAT, 0644
      io = IO.new(fd)
      mmap_prot = RGame::Core::Internal::PROT_READ |
                  RGame::Core::Internal::PROT_WRITE
      mmap_flags = RGame::Core::Internal::MAP_SHARED
      data = RGame::Core::Internal.mmap(nil, io.stat.size,
                                          mmap_prot, mmap_flags,
                                          fd, 0)
      buffer = data.read_bytes(io.stat.size)
      length = 128 * 128 * 4
      File.write("colors.bin", buffer[0...length].bytes.each_slice(4).map do |e|
        e.tap do
          e.push(e.shift)
          e[0], e[2] = [ e[2], e[0] ]
        end
      end.flatten.map { |e| e.chr }.join)
      RGame::Core::Internal.munmap(data, io.stat.size)
      RGame::Core::Internal.shm_unlink "colors.bin"
    end

    Dir.mktmpdir do |dir|
      FileUtils.cd(dir) do
        klass.run!
        base = File.join(File.dirname(__FILE__), "images/colors.png")
        %x[convert -size 128x128 -depth 8 RGBA:colors.bin tmp.png]
        assert($?.success?)
        diff = %x[compare -metric AE tmp.png #{base} out.png 2>&1]
        assert($?.exitstatus < 2)
        assert_equal(0, diff.to_f)
      end
    end
  end

  def self._draw_colors ctx
    ctx.renderer.color = 0x888888
    ctx.renderer.alpha = 0xFF
    ctx.renderer.clear

    ctx.renderer.color = 0xFF0000
    ctx.renderer.fill_rect 0, 0, 32, 32
    ctx.renderer.color = 0xffff00
    ctx.renderer.fill_rect 32, 0, 32, 32
    ctx.renderer.color = 0xff7f00
    ctx.renderer.fill_rect 64, 0, 32, 32
    ctx.renderer.color = 0x007fff
    ctx.renderer.fill_rect 96, 0, 32, 32

    ctx.renderer.color = 0x7fff00
    ctx.renderer.fill_rect 0, 32, 32, 32
    ctx.renderer.color = 0x00ff00
    ctx.renderer.fill_rect 32, 32, 32, 32
    ctx.renderer.color = 0x00ffff
    ctx.renderer.fill_rect 64, 32, 32, 32
    ctx.renderer.color = 0x7f00ff
    ctx.renderer.fill_rect 96, 32, 32, 32

    ctx.renderer.color = 0xff00ff
    ctx.renderer.fill_rect 0, 64, 32, 32
    ctx.renderer.color = 0x00ff7f
    ctx.renderer.fill_rect 32, 64, 32, 32
    ctx.renderer.color = 0x0000ff
    ctx.renderer.fill_rect 64, 64, 32, 32
    ctx.renderer.color = 0xff007f
    ctx.renderer.fill_rect 96, 64, 32, 32

    ctx.renderer.color = 0xffffff
    ctx.renderer.fill_rect 0, 96, 32, 32
    ctx.renderer.color = 0xababab
    ctx.renderer.fill_rect 32, 96, 32, 32
    ctx.renderer.color = 0x545454
    ctx.renderer.fill_rect 64, 96, 32, 32
    ctx.renderer.color = 0x000000
    ctx.renderer.fill_rect 96, 96, 32, 32
  end
end
