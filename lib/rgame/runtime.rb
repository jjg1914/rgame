# frozen_string_literal: true

require "dotenv/load"
require "rgame"

module RGame
  module Runtime
    at_exit { RGame::Common::RootEntity.run! }
  end
end
