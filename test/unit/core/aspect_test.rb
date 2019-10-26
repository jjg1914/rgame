require "rgame/core/aspect"

describe RGame::Core::Aspect do
  describe ".included" do
    it "should deliver aspect methods" do
      _aspect = Module.new do
        include RGame::Core::Aspect
      end

      mock = Minitest::Mock.new
      mock.expect "on", nil, [ "test", Proc ]
      mock.expect "before", nil, [ "test1", Proc ]
      mock.expect "after", nil, [ "test2", Proc ]
      mock.expect "around", nil, [ "test3", Proc ]

      _aspect.on("test") { mock.call }
      _aspect.before("test1") { mock.call }
      _aspect.after("test2") { mock.call }
      _aspect.around("test3") { mock.call }

      klass = Class.new
      eklass = (class << klass; self; end)
      eklass.send("define_method", "on") { |a,&b| mock.on(a, b) }
      eklass.send("define_method", "before") { |a,&b| mock.before(a, b) }
      eklass.send("define_method", "after") { |a,&b| mock.after(a, b) }
      eklass.send("define_method", "around") { |a,&b| mock.around(a, b) }

      klass.instance_eval { include _aspect }

      mock.verify
    end
  end
end
