require "entities/stage_entity"

class RootEntity < Dungeon::Common::CollectionEntity
  on :new do
    self.add(StageEntity.new.tap { |o| o.map = "stage1" })
  end

  after :interval do
    self.emit :draw
    get_var("ctx").present
  end

  on :console do |args|
    case args[0]
    when /^inspect$/i
      STDERR.puts self.inspect
      stop!
    end
  end
end
