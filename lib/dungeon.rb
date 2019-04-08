require "pry"

require "dungeon/core/ext"
require "dungeon/application"

module Dungeon
  def self.run!
    Application.run!
  end
end
