require "fileutils"

SDL2_SOURCE = "https://libsdl.org/release/SDL2-2.0.9.tar.gz"
SDL2_DEST = File.join("vendor", File.basename(SDL2_SOURCE))
SDL2_DIR = File.join("vendor", File.basename(SDL2_DEST, ".tar.gz"))
SDL2_PREFIX = File.expand_path(File.join("vendor", "SDL2"))
SDL2_CFLAGS = [
  "-arch", "X86_64",
  "-mmacosx-version-min=10.6",
  "-DMAC_OS_X_VERSION_MIN_REQUIRED=1060",
  "-I/usr/local/include",
].join(" ").inspect

task :vendor => [ :vendor_sdl ]

task :vendor_sdl => [ SDL2_DIR ] do |t|
  FileUtils.mkdir_p File.join(t.source, "build")
  FileUtils.cd(File.join(t.source, "build")) do
    sh "../configure --prefix=%s" % [ SDL2_PREFIX.inspect ]
    sh "make install"
  end
end

file SDL2_DIR => SDL2_DEST do |t|
  sh "tar -xz -C %s -f %s" % [ File.dirname(t.source), t.source ]
end

file(SDL2_DEST) do |t|
  sh "mkdir -p %s" % File.dirname(t.name)
  sh "curl -o %s %s" % [ t.name, SDL2_SOURCE ]
end
