require "dungeon/core/aspect"

module Dungeon
  module Common
    module CollisionAspect 
      include Dungeon::Core::Aspect

      after :interval do 
        get_var("collision").add(self)
      end

      on :collision do
        get_var("collision").query(self).tap do |o|
          STDERR.puts o.inspect unless o.empty?
        end
      end
    end
  end
end
