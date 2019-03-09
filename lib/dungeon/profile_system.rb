require "ruby-prof"

module Dungeon
  class ProfileSystem
    def self.open *args
      if block_given?
        a = self.open(*args)
        yield a
        a.close
      else
        self.new.tap { |o| o.open(*args) }
      end
    end

    def open
      STDERR.puts "open!"
      #GC::Profiler.enable
      RubyProf.start
    end

    def close
      ruby_prof_result = RubyProf.stop
      #File.open("gc.profile.%i" % $$, "w") { |f| GC::Profiler.report(f) }
      #GC::Profiler.disable

      File.open("ruby-prof.profile.%i" % $$, "w") do |f|
        RubyProf::FlatPrinter.new(ruby_prof_result).print f
      end
    end
  end
end
