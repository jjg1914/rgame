require "dotenv/load"
require "dungeon"

module Dungeon
  module Runtime
    at_exit { Dungeon::Common::RootEntity.run! }
  end
end
