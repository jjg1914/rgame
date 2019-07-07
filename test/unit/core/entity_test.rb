require "dungeon/core/entity"

describe Dungeon::Core::Entity do
  describe Dungeon::Core::Entity::ClassMethods do
    before do
      @base_klass = Class.new(Dungeon::Core::Entity) do
        on "test" do |x,y|
          @mock.call "test_on", x, y
        end

        before "test" do |x,y|
          @mock.call "test_before", x, y
        end

        after "test" do |x,y|
          @mock.call "test_after", x, y
        end

        on "foo" do
          @mock.call "foo_on"
          stop!
        end

        def last message, *args
          @mock.call "last", message, *args unless message == "new"
        end
      end

      @derived_klass = Class.new(@base_klass) do
        on "test" do |x,y|
          @mock.call "test_derived_on", x, y
        end

        before "test" do |x,y|
          @mock.call "test_derived_before", x, y
        end

        after "test" do |x,y|
          @mock.call "test_derived_after", x, y
        end

        on "foo" do
          @mock.call "foo_derived_on"
        end
      end

      @base_klass.instance_eval do
        on "test" do |x,y|
          @mock.call "test_on_2", x, y
        end

        before "test" do |x,y|
          @mock.call "test_before_2", x, y
        end

        after "test" do |x,y|
          @mock.call "test_after_2", x, y
        end
      end

      @subject = @base_klass.new
      @derived_subject = @derived_klass.new

      @mock = Minitest::Mock.new
      @subject.instance_variable_set :@mock, @mock
      @derived_subject.instance_variable_set :@mock, @mock
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should deliver in order" do
      @mock.expect :call, nil, [ "test_before_2", 1, 2 ]
      @mock.expect :call, nil, [ "test_before", 1, 2 ]
      @mock.expect :call, nil, [ "test_on", 1, 2  ]
      @mock.expect :call, nil, [ "test_on_2", 1, 2  ]
      @mock.expect :call, nil, [ "last", "test", 1, 2  ]
      @mock.expect :call, nil, [ "test_after", 1, 2 ]
      @mock.expect :call, nil, [ "test_after_2", 1, 2 ]
      expect(@subject.emit "test", 1 ,2).must_be :nil?
      @mock.verify
    end

    it "should deliver in order to derived class" do
      @mock.expect :call, nil, [ "test_derived_before", 1, 2 ]
      @mock.expect :call, nil, [ "test_before_2", 1, 2 ]
      @mock.expect :call, nil, [ "test_before", 1, 2 ]
      @mock.expect :call, nil, [ "test_on", 1, 2  ]
      @mock.expect :call, nil, [ "test_on_2", 1, 2  ]
      @mock.expect :call, nil, [ "test_derived_on", 1, 2  ]
      @mock.expect :call, nil, [ "last", "test", 1, 2  ]
      @mock.expect :call, nil, [ "test_after", 1, 2 ]
      @mock.expect :call, nil, [ "test_after_2", 1, 2 ]
      @mock.expect :call, nil, [ "test_derived_after", 1, 2 ]
      expect(@derived_subject.emit "test", 1 ,2).must_be :nil?
      @mock.verify
    end

    it "should not deliver when stopped" do
      @mock.expect :call, nil, [ "foo_on" ]
      expect(@derived_subject.emit "foo").must_be :nil?
      @mock.verify
    end

    it "should register subclasses" do
      expect(Dungeon::Core::Entity.registry).
        must_equal([ @base_klass, @derived_klass ])
    end
  end

  describe ".new" do
    before do
      @mock = Minitest::Mock.new
      _mock = @mock
      @klass = Class.new(Dungeon::Core::Entity) do
        on :new do
          _mock.call "new"
        end
      end
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should allocate new entity" do
      @mock.expect :call, nil, [ "new" ]
      old_id = Dungeon::Core::Entity.id_counter
      subject = @klass.new
      expect(subject.id).must_equal(old_id + 1)
      @mock.verify
    end

    it "should increment id counter" do
      @mock.expect :call, nil, [ "new" ]
      old_id = Dungeon::Core::Entity.id_counter
      @klass.new
      expect(Dungeon::Core::Entity.id_counter).must_equal(old_id + 1)
      @mock.verify
    end
  end

  describe "#dup" do
    before do
      @mock = Minitest::Mock.new
      _mock = @mock
      @klass = Class.new(Dungeon::Core::Entity) do
        on :new do
          _mock.call "new", self
        end

        on :copy do
          _mock.call "copy", self
        end
      end
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should use new id" do
      @mock.expect(:call, nil) { |a,b| a == "new" }
      @mock.expect(:call, nil) { |a,b| a == "copy" }

      subject = @klass.new
      subject.parent = :foo
      subject2 = subject.dup
      expect(subject2.id).wont_equal subject.id
      @mock.verify
    end

    it "should nil parent" do
      @mock.expect(:call, nil) { |a,b| a == "new" }
      @mock.expect(:call, nil) { |a,b| a == "copy" }

      subject = @klass.new
      subject.parent = :foo
      subject2 = subject.dup
      expect(subject2.parent).must_be :nil?
      @mock.verify
    end

    it "should emit copy to new object" do
      tmp = nil
      tmp2 = nil
      @mock.expect(:call, nil) do |a,b|
        tmp = b
        a == "new"
      end
      @mock.expect(:call, nil) do |a,b|
        tmp2 = b
        a == "copy"
      end

      subject = @klass.new
      subject.parent = :foo
      subject2 = subject.dup
      expect([ tmp, tmp2 ]).must_equal [ subject, subject2 ]
      @mock.verify
    end

    it "should copy object" do
      @mock.expect(:call, nil) { |a,b| a == "new" }
      @mock.expect(:call, nil) { |a,b| a == "copy" }

      subject = @klass.new
      subject.parent = :foo
      subject2 = subject.dup
      expect(subject2.class).must_equal @klass
      @mock.verify
    end
  end

  describe "#broadcast" do
    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should emit message to root parent" do
      mock = Minitest::Mock.new
      mock.expect "nil?", false, []
      mock.expect "parent", nil, []
      mock.expect "emit", nil, [ "test", 1, 2 ]

      mock2 = Minitest::Mock.new
      mock2.expect "nil?", false, []
      mock2.expect "parent", mock, []

      klass = Class.new(Dungeon::Core::Entity)
      subject = klass.new
      subject.parent = mock2
      expect(subject.broadcast("test", 1, 2)).must_be :nil?
      mock.verify
      mock2.verify
    end

    it "should emit message to parent" do
      mock = Minitest::Mock.new
      mock.expect "nil?", false, []
      mock.expect "parent", nil, []
      mock.expect "emit", nil, [ "test", 1, 2 ]

      klass = Class.new(Dungeon::Core::Entity)
      subject = klass.new
      subject.parent = mock
      expect(subject.broadcast("test", 1, 2)).must_be :nil?
      mock.verify
    end

    it "should emit message to self" do
      mock = Minitest::Mock.new
      mock.expect "call", nil, [ "test", 1, 2 ]

      klass = Class.new(Dungeon::Core::Entity)
      subject = klass.new
      subject.stub(:emit, lambda { |msg, a, b| mock.call(msg, a, b) }) do
        expect(subject.broadcast("test", 1, 2)).must_be :nil?
      end
      mock.verify
    end
  end

  describe "#remove" do
    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should remove from parent" do
      klass = Class.new(Dungeon::Core::Entity)
      subject = klass.new

      mock = Minitest::Mock.new
      mock.expect "remove", nil, [ subject ]

      subject.parent = mock
      expect(subject.remove).must_be :nil?
      mock.verify
    end

    it "should not remove from nil" do
      klass = Class.new(Dungeon::Core::Entity)
      subject = klass.new

      subject.parent = nil
      expect(subject.remove).must_be :nil?
    end
  end

  describe "#on" do
    before do
      @klass = Class.new(Dungeon::Core::Entity)
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should only dispatch to entity" do
      mock = Minitest::Mock.new
      mock.expect "call", nil, [ "test_on", 1, 2 ]

      subject = @klass.new
      other = @klass.new

      expect(subject.on("test") { |a, b| mock.call("test_on", a, b) })
        .must_be_kind_of(Proc)
      subject.emit "test", 1, 2
      other.emit "test", 1, 2

      mock.verify
    end

    it "should provide cancel" do
      mock = Minitest::Mock.new

      subject = @klass.new

      p = subject.on("test") { |a, b| mock.call("test_on", a, b) }
      expect(p).must_be_kind_of(Proc)
      p.call
      subject.emit "test", 1, 2

      mock.verify
    end
  end

  describe "#before" do
    before do
      @klass = Class.new(Dungeon::Core::Entity)
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should only dispatch to entity" do
      mock = Minitest::Mock.new
      mock.expect "call", nil, [ "test_before", 1, 2 ]

      subject = @klass.new
      other = @klass.new

      expect(subject.before("test") { |a, b| mock.call("test_before", a, b) })
        .must_be_kind_of(Proc)
      subject.emit "test", 1, 2
      other.emit "test", 1, 2

      mock.verify
    end

    it "should provide cancel" do
      mock = Minitest::Mock.new

      subject = @klass.new

      p = subject.before("test") { |a, b| mock.call("test_before", a, b) }
      expect(p).must_be_kind_of(Proc)
      p.call
      subject.emit "test", 1, 2

      mock.verify
    end
  end

  describe "#after" do
    before do
      @klass = Class.new(Dungeon::Core::Entity)
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should only dispatch to entity" do
      mock = Minitest::Mock.new
      mock.expect "call", nil, [ "test_after", 1, 2 ]

      subject = @klass.new
      other = @klass.new

      expect(subject.after("test") { |a, b| mock.call("test_after", a, b) })
        .must_be_kind_of(Proc)
      subject.emit "test", 1, 2
      other.emit "test", 1, 2

      mock.verify
    end

    it "should provide cancel" do
      mock = Minitest::Mock.new

      subject = @klass.new

      p = subject.after("test") { |a, b| mock.call("test_after", a, b) }
      expect(p).must_be_kind_of(Proc)
      p.call
      subject.emit "test", 1, 2

      mock.verify
    end
  end

  describe "#around" do
    before do
      @klass = Class.new(Dungeon::Core::Entity)
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should only dispatch to entity" do
      mock = Minitest::Mock.new
      mock.expect("call", nil) do |*args|
        args.size == 4 and
          args[0] == "test_around" and
          args[1].kind_of?(Proc) and
          args.drop(2) == [ 1, 2 ]
      end

      subject = @klass.new
      other = @klass.new

      expect(subject.around("test") { |p, a, b| mock.call("test_around", p, a, b) })
        .must_be_kind_of(Proc)
      subject.emit "test", 1, 2
      other.emit "test", 1, 2

      mock.verify
    end

    it "should provide cancel" do
      mock = Minitest::Mock.new

      subject = @klass.new

      p = subject.around("test") { |p, a, b| mock.call("test_around", p, a, b) }
      expect(p).must_be_kind_of(Proc)
      p.call
      subject.emit "test", 1, 2

      mock.verify
    end
  end

  describe "#active" do
    before do
      klass = Class.new(Dungeon::Core::Entity)
      @subject = klass.new
    end

    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should activate" do
      @subject.active = false
      @subject.activate!
      expect(@subject.active).must_equal true
    end

    it "should deativate" do
      @subject.active = true
      @subject.deactivate!
      expect(@subject.active).must_equal false
    end

    it "should toggle active" do
      @subject.active = true
      @subject.toggle!
      expect(@subject.active).must_equal false
    end

    it "should toggle inactive" do
      @subject.active = false
      @subject.toggle!
      expect(@subject.active).must_equal true
    end

    it "should be inactive" do
      @subject.active = false
      expect(@subject).must_be :inactive?
    end

    it "should not be inactive" do
      @subject.active = true
      expect(@subject).wont_be :inactive?
    end
  end

  describe "#to_h" do
    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should hasherize enitity" do
      klass = Class.new(Dungeon::Core::Entity) do
        def self.to_s
          "Bar::FooEntity"
        end
      end
      subject = klass.new
      expect(subject.to_h).must_equal({
        "id" => subject.id,
        "active" => true,
        "type" => "bar::foo",
      })
    end
  end

  describe "#inspect" do
    after do
      Dungeon::Core::Entity.registry.clear
    end

    it "should inspect enitity" do
      klass = Class.new(Dungeon::Core::Entity) do
        def self.to_s
          "Bar::FooEntity"
        end

        def to_h
          super.merge({
            "id" => 123,
            "a" => 1,
            "b" => "2",
            "c" => [ 3 ],
          })
        end
      end
      subject = klass.new
      expect(subject.inspect).must_equal(<<-EOS.strip % subject.id)
        #<Bar::FooEntity id=%i active=true a=1 b="2" c=[3]>
      EOS
    end
  end
end
