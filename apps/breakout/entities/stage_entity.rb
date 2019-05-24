require "entities/player_entity"
require "entities/ball_entity"
require "entities/block_entity"

class StageEntity < Dungeon::Common::MapEntity
  include Dungeon::Common::EditorAspect
  
  on :mapupdate do
    self.add(player = PlayerEntity.new.tap do |o|
      o.x = ((self.width - 8 - o.width) / 2) + 8
      o.y = self.height - 32

      o.x_restrict = (8..(self.width - o.width - 8))
    end)

    self.add(BallEntity.new.tap do |o|
      o.player = player
      o.x_restrict = (8..(self.width - o.width - 8))
      o.y_restrict = (8..)
    end)
  end
end
