require "entities/stage_entity"

class RootEntity < Dungeon::Common::CollectionEntity
  on :new do
    self.add(StageEntity.new "stage1")
  end

  after :interval do
    self.emit :draw
    get_var("ctx").present
  end
end
