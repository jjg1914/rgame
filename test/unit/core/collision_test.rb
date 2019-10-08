require "ostruct"
require "rgame/core/collision"

describe RGame::Core::Collision do
  describe RGame::Core::Collision::CollisionInfo do
    before do
      @target = OpenStruct.new
      @target.x = 0
      @target.y = 0
      @target.width  = 3
      @target.height = 3

      @other = OpenStruct.new
      @other.x = 0
      @other.y = 0
      @other.width  = 5
      @other.height = 5

      @subject = RGame::Core::Collision::CollisionInfo.new @target, @other
    end

    describe "#mtv" do
      before do
        @target.x = 1
        @target.y = 2
        @target.freeze
        @other.freeze
      end

      it "should return mtv" do
        expect(@subject.mtv).must_equal([ -3, 2 ])
      end
    end

    describe "#normal" do
      it "should return sweep normal" do
        @subject.stub(:sweep, lambda { [ 1, [ 2, 3 ] ] }) do
          expect(@subject.normal).must_equal([ 2, 3 ])
        end
      end
    end

    describe "#time" do
      it "should return sweep time" do
        @subject.stub(:sweep, lambda { [ 1, [ 2, 3 ] ] }) do
          expect(@subject.time).must_equal(1)
        end
      end
    end

    describe "#position" do
      describe "with positive change" do
        before do
          @target.x_change = 4
          @target.y_change = 4
          @target.freeze
        end

        it "should return new position" do
          @subject.stub(:time, lambda { 0.5 }) do
            expect(@subject.position).must_equal( [ -2, -2 ])
          end
        end
      end

      describe "with negative change" do
        before do
          @target.x_change = -4
          @target.y_change = -4
          @target.freeze
        end

        it "should return new position" do
          @subject.stub(:time, lambda { 0.75 }) do
            expect(@subject.position).must_equal( [ 1, 1 ])
          end
        end
      end
    end

    describe "#sweep" do
      describe "without change" do
        before do
          @target.x = 1
          @target.y = 1
          @target.freeze

          @other.x = 2
          @other.y = 2
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 1, [ 0, 0 ] ])
        end
      end

      describe "without collision change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1 T T T
          #  2 T T T
          #  3 T T T
          #  4
          #  5
          #  6       O O O O
          #  7       O O O O
          #  8       O O O O
          #  9       O O O O
          # 10

          @target.x = 1
          @target.y = 1
          @target.x_change = 4
          @target.y_change = 0
          @target.freeze

          @other.x = 4
          @other.y = 6
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 1, [ 0, 0 ] ])
        end
      end

      describe "with positive change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1
          #  2
          #  3
          #  4
          #  5     T T T
          #  6     T T T O O
          #  7     T T T O O
          #  8       O O O O
          #  9       O O O O
          # 10

          @target.x = 3
          @target.y = 5
          @target.x_change = 4
          @target.y_change = 0
          @target.freeze

          @other.x = 4
          @other.y = 6
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 0.75, [ -1, 0 ] ])
        end
      end

      describe "with negative change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1
          #  2
          #  3
          #  4
          #  5     O O O O
          #  6     O O O O
          #  7     O O T T T
          #  8     O O T T T
          #  9         T T T
          # 10

          @target.x = 6
          @target.y = 7
          @target.x_change = -4
          @target.y_change = -5
          @target.freeze

          @other.x = 3
          @other.y = 5
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 0.75, [ 1, 0 ] ])
        end
      end

      describe "with zero change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1
          #  2
          #  3
          #  4
          #  5     O O O O
          #  6     O O O O
          #  7     O O T T T
          #  8     O O T T T
          #  9         T T T
          # 10

          @target.x = 6
          @target.y = 7
          @target.x_change = 0
          @target.y_change = 0
          @target.freeze

          @other.x = 3
          @other.y = 5
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 1, [ 0, 0 ] ])
        end
      end

      describe "with large change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1
          #  2
          #  3
          #  4
          #  5     O O O O
          #  6     O O O O
          #  7     O O T T T
          #  8     O O T T T
          #  9         T T T
          # 10

          @target.x = 6
          @target.y = 7
          @target.x_change = 8
          @target.y_change = 8
          @target.freeze

          @other.x = 3
          @other.y = 5
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 0.5, [ 0, -1 ] ])
        end
      end
    end
  end

  describe RGame::Core::Collision::ReverseCollisionInfo do
    before do
      @target = OpenStruct.new
      @target.x = 0
      @target.y = 0
      @target.width  = 3
      @target.height = 3

      @other = {
        "left" => 0,
        "top" => 0,
        "right" => 4,
        "bottom" => 4,
      }

      @subject = RGame::Core::Collision::ReverseCollisionInfo.new @target,
                                                                  @other
    end

    describe "#mtv" do
      before do
        @target.x = -1
        @target.y = 2
        @target.freeze
        @other.freeze
      end

      it "should return mtv" do
        expect(@subject.mtv).must_equal([ 1, 0 ])
      end
    end

    describe "#sweep" do
      describe "without change" do
        before do
          @target.x = 1
          @target.y = 2
          @target.freeze
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 1, [ 0,  0 ] ])
        end
      end

      describe "without collision change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1 T T T
          #  2 T T T
          #  3 T T T
          #  4
          #  5
          #  6       O O O O
          #  7       O O O O
          #  8       O O O O
          #  9       O O O O
          # 10

          @target.x = 1
          @target.y = 1
          @target.freeze

          @other["left"] = 4
          @other["top"] = 6
          @other["right"] = 7
          @other["bottom"] = 9
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 1, [ 0, 0 ] ])
        end
      end

      describe "with negative change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1
          #  2
          #  3
          #  4
          #  5     T T T
          #  6     T T T O O O
          #  7     T T T O O O
          #  8       O O O O O
          #  9       O O O O O
          # 10       O O O O O

          @target.x = 3
          @target.y = 5
          @target.x_change = -2
          @target.y_change = -2
          @target.freeze

          @other["left"] = 4
          @other["top"] = 6
          @other["right"] = 8
          @other["bottom"] = 10
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 0.5, [ 0, 1 ] ])
        end
      end

      describe "with positive change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1
          #  2
          #  3
          #  4
          #  5          
          #  6       O O O O O
          #  7       O O O T T T
          #  8       O O O T T T
          #  9       O O O T T T
          # 10       O O O O O

          @target.x = 7
          @target.y = 7
          @target.x_change = 2
          @target.y_change = 0
          @target.freeze

          @other["left"] = 4
          @other["top"] = 6
          @other["right"] = 8
          @other["bottom"] = 10
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 0.5, [ -1, 0 ] ])
        end
      end

      describe "with zero change" do
        before do
          @target.x = 6
          @target.y = 7
          @target.x_change = 0
          @target.y_change = 0
          @target.freeze

          @other["left"] = 5
          @other["top"] = 6
          @other["right"] = 9
          @other["bottom"] = 10
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 1, [ 0, 0 ] ])
        end
      end

      describe "with large change" do
        before do
          #    1 2 3 4 5 6 7 8 9 10
          #  1     T T T
          #  2     T T T
          #  3     T T T
          #  4
          #  5   O O O O O
          #  6   O O O O O
          #  7   O O O O O
          #  8   O O O O O
          #  9   O O O O O
          # 10

          @target.x = 3
          @target.y = 1
          @target.x_change = 0
          @target.y_change = -5
          @target.freeze

          @other["left"] = 2
          @other["top"] = 5
          @other["right"] = 6
          @other["bottom"] = 9
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 0.2, [ 0, 1 ] ])
        end
      end

      describe "with small change" do
        before do
          @target.x = 7
          @target.y = 180
          @target.x_change = -1
          @target.y_change = 0
          @target.freeze

          @other["left"] = 8
          @other["top"] = 8
          @other["right"] = 208
          @other["bottom"] = 208
          @other.freeze
        end

        it "should return sweep" do
          expect(@subject.sweep).must_equal([ 0, [ 1, 0 ] ])
        end
      end
    end
  end

  describe ".check" do
    describe "inside" do
      it "should be true" do
        a = Object.new
        class << a
          def x; 1; end
          def y; 2; end
          def width; 3; end
          def height; 4; end
        end

        b = Object.new
        class << b
          def x; 0; end
          def y; 1; end
          def width; 5; end
          def height; 6; end
        end

        expect(RGame::Core::Collision.check(a, b)).must_equal true
      end
    end
  end

  describe ".check_bounds" do
    describe "left" do
      it "should be false" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => -2,
          "top" => 2,
          "right" => 0,
          "bottom" => 5,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => -1,
          "top" => 2,
          "right" => 1,
          "bottom" => 5,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "right" do
      it "should be false" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => 4,
          "top" => 2,
          "right" => 7,
          "bottom" => 5,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => 3,
          "top" => 2,
          "right" => 6,
          "bottom" => 5,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "top" do
      it "should be false" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => 1,
          "top" => -1,
          "right" => 3,
          "bottom" => 1,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => 1,
          "top" => -1,
          "right" => 3,
          "bottom" => 2,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "bottom" do
      it "should be false" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => 1,
          "top" => 6,
          "right" => 3,
          "bottom" => 10,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => 1,
          "top" => 5,
          "right" => 3,
          "bottom" => 10,
        }, {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "inside" do
      it "should be true" do
        expect(RGame::Core::Collision.check_bounds({
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        }, {
          "left" => 0,
          "top" => 1,
          "right" => 4,
          "bottom" => 6,
        })).must_equal true
      end
    end
  end

  describe ".check_point" do
    it "should be true" do
      o = Object.new
      class << o
        def x; 1; end
        def y; 2; end
        def width; 3; end
        def height; 4; end
      end

      expect(RGame::Core::Collision.check_point([ 2, 4 ], o)).must_equal true
    end
  end

  describe ".check_point_bounds" do
    describe "left" do
      it "should be false" do
        expect(RGame::Core::Collision.check_point_bounds([ 0, 4 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_point_bounds([ 1, 4 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "right" do
      it "should be false" do
        expect(RGame::Core::Collision.check_point_bounds([ 4, 4 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_point_bounds([ 3, 4 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "top" do
      it "should be false" do
        expect(RGame::Core::Collision.check_point_bounds([ 2, 1 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_point_bounds([ 2, 2 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "bottom" do
      it "should be false" do
        expect(RGame::Core::Collision.check_point_bounds([ 2, 6 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal false
      end

      it "should be true on border" do
        expect(RGame::Core::Collision.check_point_bounds([ 2, 5 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end

    describe "inside" do
      it "should be true" do
        expect(RGame::Core::Collision.check_point_bounds([ 2, 4 ], {
          "left" => 1,
          "top" => 2,
          "right" => 3,
          "bottom" => 5,
        })).must_equal true
      end
    end
  end

  describe ".bounds_for" do
    it "should return bounds" do
      o = Object.new
      class << o
        def x; 1; end
        def y; 2; end
        def width; 3; end
        def height; 4; end
      end

      expect(RGame::Core::Collision.bounds_for(o)).must_equal({
        "left" => 1,
        "top" => 2,
        "right" => 3,
        "bottom" => 5,
      })
    end
  end

  describe "#add" do
    before do
      @entities = []
      @entities << Object.new.tap do |o|
        class << o
          def x; 1; end
          def y; 2; end
          def width; 3; end
          def height; 4; end
        end
      end
      10.times do
        @entities << Object.new.tap do |o|
          class << o
            def x; 65; end
            def y; 2; end
            def width; 3; end
            def height; 4; end
          end
        end
      end
      @entities << Object.new.tap do |o|
        class << o
          def x; 139; end
          def y; 2; end
          def width; 3; end
          def height; 4; end
        end
      end

      @subject = RGame::Core::Collision.new 128, 256
    end

    it "should add entities" do
      @entities.each { |e| @subject.add e }
      expect(@subject.size).must_equal 11
      expect(@subject.root.mode).must_equal "branch"
      expect(@subject.root.depth).must_equal 0
      expect(@subject.root.bounds).must_equal({
        "left" => 0,
        "top" => 0,
        "right" => 127,
        "bottom" => 255,
      })

      expect(@subject.root.children[0].mode).must_equal "leaf"
      expect(@subject.root.children[0].depth).must_equal 1
      expect(@subject.root.children[0].bounds).must_equal({
        "left" => 0,
        "top" => 0,
        "right" => 63,
        "bottom" => 127,
      })
      expect(@subject.root.children[0].children).must_equal [
        [
          {
            "left" => 1,
            "top" => 2,
            "right" => 3,
            "bottom" => 5,
          },
          @entities[0],
        ]
      ]

      expect(@subject.root.children[1].mode).must_equal "leaf"
      expect(@subject.root.children[1].depth).must_equal 1
      expect(@subject.root.children[1].bounds).must_equal({
        "left" => 64,
        "top" => 0,
        "right" => 127,
        "bottom" => 127,
      })
      expect(@subject.root.children[1].children).must_equal(@entities.slice(1..10).map do |e|
        [
          {
            "left" => e.x,
            "top" => e.y,
            "right" => e.x + e.width - 1,
            "bottom" => e.y + e.height - 1,
          },
          e,
        ]
      end)

      expect(@subject.root.children[2].mode).must_equal "leaf"
      expect(@subject.root.children[2].depth).must_equal 1
      expect(@subject.root.children[2].bounds).must_equal({
        "left" => 0,
        "top" => 128,
        "right" => 63,
        "bottom" => 255,
      })
      expect(@subject.root.children[2].children).must_equal([])

      expect(@subject.root.children[3].mode).must_equal "leaf"
      expect(@subject.root.children[3].depth).must_equal 1
      expect(@subject.root.children[3].bounds).must_equal({
        "left" => 64,
        "top" => 128,
        "right" => 127,
        "bottom" => 255,
      })
      expect(@subject.root.children[3].children).must_equal([])
    end
  end

  describe "#query" do
    before do
      @entities = []
      @entities << Object.new.tap do |o|
        class << o
          def id; 0; end
          def x; 1; end
          def y; 2; end
          def width; 3; end
          def height; 4; end
        end
      end
      10.times do |i|
        @entities << Object.new.tap do |o|
          class << o
            attr_accessor :id
            def x; 65; end
            def y; 2; end
            def width; 3; end
            def height; 4; end
          end
          o.id == i + 1
        end
      end

      @subject = RGame::Core::Collision.new 128, 256
      @entities.each { |e| @subject.add e }
    end

    it "should return collisions" do
      entity = Object.new.tap do |o|
        class << o
          def id; 12; end
          def x; 1; end
          def y; 2; end
          def width; 3; end
          def height; 4; end
        end
      end
      
      expect(@subject.query(entity)).must_equal [ @entities[0] ]
    end

    it "should not return self" do
      entity = Object.new.tap do |o|
        class << o
          def id; 0; end
          def x; 1; end
          def y; 2; end
          def width; 3; end
          def height; 4; end
        end
      end
      
      expect(@subject.query(entity)).must_equal []
    end
  end

  describe "#clear" do
    before do
      @entities = []
      @entities << Object.new.tap do |o|
        class << o
          def id; 0; end
          def x; 1; end
          def y; 2; end
          def width; 3; end
          def height; 4; end
        end
      end
      10.times do |i|
        @entities << Object.new.tap do |o|
          class << o
            attr_accessor :id
            def x; 65; end
            def y; 2; end
            def width; 3; end
            def height; 4; end
          end
          o.id == i + 1
        end
      end
      10.times do |i|
        @entities << Object.new.tap do |o|
          class << o
            attr_accessor :id
            def x; 97; end
            def y; 2; end
            def width; 3; end
            def height; 4; end
          end
          o.id == i + 11
        end
      end

      @subject = RGame::Core::Collision.new 128, 256
      @entities.each { |e| @subject.add e }
    end

    it "should clear tree" do
      @subject.clear

      expect(@subject.size).must_equal 0
      expect(@subject.root.mode).must_equal "branch"
      expect(@subject.root.depth).must_equal 0
      expect(@subject.root.bounds).must_equal({
        "left" => 0,
        "top" => 0,
        "right" => 127,
        "bottom" => 255,
      })

      expect(@subject.root.children[0].mode).must_equal "leaf"
      expect(@subject.root.children[0].depth).must_equal 1
      expect(@subject.root.children[0].bounds).must_equal({
        "left" => 0,
        "top" => 0,
        "right" => 63,
        "bottom" => 127,
      })
      expect(@subject.root.children[0].children).must_equal []

      expect(@subject.root.children[1].mode).must_equal "branch"
      expect(@subject.root.children[1].depth).must_equal 1
      expect(@subject.root.children[1].bounds).must_equal({
        "left" => 64,
        "top" => 0,
        "right" => 127,
        "bottom" => 127,
      })

      expect(@subject.root.children[1].children[0].mode).must_equal "leaf"
      expect(@subject.root.children[1].children[0].depth).must_equal 2
      expect(@subject.root.children[1].children[0].bounds).must_equal({
        "left" => 64,
        "top" => 0,
        "right" => 95,
        "bottom" => 63,
      })

      expect(@subject.root.children[1].children[1].mode).must_equal "leaf"
      expect(@subject.root.children[1].children[1].depth).must_equal 2
      expect(@subject.root.children[1].children[1].bounds).must_equal({
        "left" => 96,
        "top" => 0,
        "right" => 127,
        "bottom" => 63,
      })

      expect(@subject.root.children[1].children[2].mode).must_equal "leaf"
      expect(@subject.root.children[1].children[2].depth).must_equal 2
      expect(@subject.root.children[1].children[2].bounds).must_equal({
        "left" => 64,
        "top" => 64,
        "right" => 95,
        "bottom" => 127,
      })

      expect(@subject.root.children[1].children[3].mode).must_equal "leaf"
      expect(@subject.root.children[1].children[3].depth).must_equal 2
      expect(@subject.root.children[1].children[3].bounds).must_equal({
        "left" => 96,
        "top" => 64,
        "right" => 127,
        "bottom" => 127,
      })

      expect(@subject.root.children[2].mode).must_equal "leaf"
      expect(@subject.root.children[2].depth).must_equal 1
      expect(@subject.root.children[2].bounds).must_equal({
        "left" => 0,
        "top" => 128,
        "right" => 63,
        "bottom" => 255,
      })
      expect(@subject.root.children[2].children).must_equal([])

      expect(@subject.root.children[3].mode).must_equal "leaf"
      expect(@subject.root.children[3].depth).must_equal 1
      expect(@subject.root.children[3].bounds).must_equal({
        "left" => 64,
        "top" => 128,
        "right" => 127,
        "bottom" => 255,
      })
      expect(@subject.root.children[3].children).must_equal([])
    end

    it "should unsplit tree" do
      @subject.clear
      @subject.clear

      expect(@subject.size).must_equal 0
      expect(@subject.root.mode).must_equal "leaf"
      expect(@subject.root.depth).must_equal 0
      expect(@subject.root.bounds).must_equal({
        "left" => 0,
        "top" => 0,
        "right" => 127,
        "bottom" => 255,
      })
      expect(@subject.root.children).must_equal([])
    end
  end
end
