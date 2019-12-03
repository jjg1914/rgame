require "rgame/core/savable"

describe RGame::Core::Savable do
  module Foo
    class Nested
      attr_accessor :val

      def initialize
        @val = "!val"
      end 

      def == other
        other.is_a?(self.class) and self.is_a?(other.class) and
          self.val == other.val
      end

      def to_h
        { "val" => self.val }
      end
    end

    class KlassEntity
      attr_accessor :context
      attr_accessor :foo
      attr_accessor :bar
      attr_accessor :baz
      attr_reader :nested

      include RGame::Core::Savable

      savable [ :foo, :"nested.val" ], :baz

      def initialize ctx
        @context = ctx
        @foo = "!foo"
        @bar = "!bar"
        @baz = "!baz"
        @nested = Nested.new 
      end

      def == other
        other.is_a?(self.class) and self.is_a?(other.class) and
          self.context == other.context and
          self.foo == other.foo and
          self.bar == other.bar and
          self.baz == other.baz and
          self.nested == other.nested
      end

      def to_h
        {
          "type" => "i can decide!",
          "foo" => self.foo,
          "bar" => self.bar,
          "baz" => self.baz,
          "nested" => self.nested.to_h,
        }
      end
    end
  end

  class RGame::FooEntity < Foo::KlassEntity
    attr_accessor :car

    savable :car

    def initialize ctx
      super
      @car = "!car"
    end

    def == other
      super(other) and self.car == other.car
    end

    def to_h
      super.merge({ "car" => self.car })
    end
  end

  describe ".load" do
    it "should load data" do
      expected = Foo::KlassEntity.new "_ctx_"
      expected.foo = 1
      expected.baz = 3
      expected.nested.val = 6

      expect(RGame::Core::Savable.load({
        "type" => "foo::klass",
        "foo" => 1,
        "bar" => 2,
        "baz" => 3,
        "dummy" => 4,
        "car" => 5,
        "nested" => { "val" => 6 }
      }, "_ctx_")).must_equal(expected)
    end

    it "should load child class data" do
      expected = RGame::FooEntity.new "_ctx_"
      expected.foo = 1
      expected.baz = 3
      expected.car = 5
      expected.nested.val = 6

      expect(RGame::Core::Savable.load({
        "type" => "rgame::foo",
        "foo" => 1,
        "bar" => 2,
        "baz" => 3,
        "dummy" => 4,
        "car" => 5,
        "nested" => { "val" => 6 }
      }, "_ctx_")).must_equal(expected)
    end
  end

  describe "#savable_dump" do
    it "should dump data" do
      subject = Foo::KlassEntity.new "_ctx_"

      expect(subject.savable_dump).must_equal({
        "type" => "i can decide!",
        "foo" => "!foo",
        "baz" => "!baz",
        "nested" => { "val" => "!val" },
      })
    end

    it "should dump child class data" do
      subject = RGame::FooEntity.new "_ctx_"

      expect(subject.savable_dump).must_equal({
        "type" => "i can decide!",
        "foo" => "!foo",
        "baz" => "!baz",
        "car" => "!car",
        "nested" => { "val" => "!val" },
      })
    end
  end
end
