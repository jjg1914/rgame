require "entities/player_entity"
require "entities/ball_entity"
require "entities/block_entity"

class StageEntity < Dungeon::Common::MapEntity
  include Dungeon::Common::EditorAspect
  
  on :new do
    player = PlayerEntity.new.tap do |o|
      o.x = ((240 - 8 - o.width) / 2) + 8
      o.y = 252

      o.x_restrict = (8..(240 - o.width))

      self.add o
    end

    BallEntity.new.tap do |o|
      o.player = player
      o.x_restrict = (8..(240 - o.width))
      o.y_restrict = (8..)

      self.add o
    end
  end
end
