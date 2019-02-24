require "ruby-prof"

module Dungeon
  class ProfileSystem
    def self.open *args
      if block_given?
        video = self.open(*args)
        yield video
        video.close
      else
        self.new.tap { |o| o.open(*args) }
      end
    end

    def open
      GC::Profiler.enable
      RubyProf.start
    end

    def close
      ruby_prof_result = RubyProf.stop
      GC::Profiler.disable

      File.open("gc.profile.%i" % $$, "w") { |f| GC::Profiler.report(f) }
      File.open("ruby-prof.profile.%i" % $$, "w") do |f|
        RubyProf::FlatPrinter.new(ruby_prof_result).print f
      end
    end
  end
end
