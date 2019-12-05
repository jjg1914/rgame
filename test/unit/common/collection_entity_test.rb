require "rgame/common/collection_entity"

describe RGame::Common::CollectionEntity do
  before do
    @double_class = Class.new(Object) do
      attr_reader :id

      def initialize id, mock
        @id = id
        @mock = mock
      end

      def parent= value
        @mock.parent = value
      end

      def emit *args
        @mock.emit(*args)
      end

      def inspect
        @mock.inspect
      end
    end
  end

  describe "#add_front" do
    it "should add children" do
      subject = RGame::Common::CollectionEntity.new

      mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ subject ]
        m.expect :emit, nil, [ "add" ]
        m
      end

      children = mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      children.each { |e| subject.add_front(e) }

      expect(subject.children).must_equal children.reverse

      mocks.each { |e| e.verify }
    end

    it "should throw on double add" do
      subject = RGame::Common::CollectionEntity.new

      mocks = 2.times.map do |i|
        m = Minitest::Mock.new
        if i.zero?
          m.expect :parent=, nil, [ subject ]
          m.expect :emit, nil, [ "add" ]
        end
        m
      end

      children = mocks.map do |e|
        @double_class.new(32, e)
      end

      expect(proc do
        children.each { |e| subject.add_front(e) }
      end).must_raise(IndexError)

      mocks.each { |e| e.verify }
    end
  end

  describe "#add_back" do
    it "should add children" do
      subject = RGame::Common::CollectionEntity.new

      mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ subject ]
        m.expect :emit, nil, [ "add" ]
        m
      end

      children = mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      children.each { |e| subject.add_back(e) }

      expect(subject.children).must_equal children

      mocks.each { |e| e.verify }
    end

    it "should throw on double add" do
      subject = RGame::Common::CollectionEntity.new

      mocks = 2.times.map do |i|
        m = Minitest::Mock.new
        if i.zero?
          m.expect :parent=, nil, [ subject ]
          m.expect :emit, nil, [ "add" ]
        end
        m
      end

      children = mocks.map do |e|
        @double_class.new(32, e)
      end

      expect(proc do
        children.each { |e| subject.add_back(e) }
      end).must_raise(IndexError)

      mocks.each { |e| e.verify }
    end
  end

  describe "#add_bulk" do
    it "should add children" do
      subject = RGame::Common::CollectionEntity.new

      mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ subject ]
        m.expect :emit, nil, [ "add" ]
        m
      end

      children = mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      subject.add_bulk(children)

      expect(subject.children).must_equal children

      mocks.each { |e| e.verify }
    end

    it "should throw on double add" do
      subject = RGame::Common::CollectionEntity.new

      mocks = 2.times.map do |i|
        m = Minitest::Mock.new
        if i.zero?
          m.expect :parent=, nil, [ subject ]
          m.expect :emit, nil, [ "add" ]
        end
        m
      end

      children = mocks.map do |e|
        @double_class.new(32, e)
      end

      expect(proc do
        subject.add_bulk(children)
      end).must_raise(IndexError)

      mocks.each { |e| e.verify }
    end
  end

  describe "#create" do
    it "should make and add entity" do
      subject = RGame::Common::CollectionEntity.new "_ctx_"

      mock_1 = Minitest::Mock.new
      mock_1.expect :parent=, nil, [ subject ]
      mock_1.expect :emit, nil, [ "add" ]

      double = @double_class.new 123, mock_1

      mock_2 = Minitest::Mock.new
      mock_2.expect :new, double, [ "_ctx_" ]

      mock_3 = Minitest::Mock.new
      mock_3.expect :call, nil, [ double ]

      expect(subject.create(mock_2) do |*args|
        mock_3.call(*args)
      end).must_equal(double)

      [ mock_1, mock_2, mock_3 ].each { |e| e.verify }
    end
  end

  describe "#remove" do
    before do
      @subject = RGame::Common::CollectionEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "add" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @subject.add_bulk(@children)
    end

    describe "with target" do
      it "should remove target" do
        @mocks[1].expect :emit, nil, [ "remove" ]
        @mocks[1].expect :parent=, nil, [ nil ]

        @subject.remove(@children[1])
        expect(@subject.children).must_equal @children.dup.tap { |o| o.slice!(1) }

        @mocks.each(&:verify)
      end

      it "should raise on missing target" do
        double = @double_class.new 34, nil

        expect(proc do
          @subject.remove(double)
        end).must_raise IndexError

        @mocks.each(&:verify)
      end
    end

    describe "with target" do
      it "should remove self" do
        mock_parent = Minitest::Mock.new
        mock_parent.expect :remove, nil, [ @subject ]
        @subject.parent = mock_parent
        
        @subject.remove
        expect(@subject.children).must_equal @children

        mock_parent.verify
        @mocks.each(&:verify)
      end
    end
  end

  describe "#remove_bulk" do
    before do
      @subject = RGame::Common::CollectionEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "add" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @subject.add_bulk(@children)
    end

    it "should remove targets" do
      @mocks[0].expect :emit, nil, [ "remove" ]
      @mocks[0].expect :parent=, nil, [ nil ]
      @mocks[2].expect :emit, nil, [ "remove" ]
      @mocks[2].expect :parent=, nil, [ nil ]

      @subject.remove_bulk([ @children[0], @children[2] ])
      expect(@subject.children).must_equal [ @children[1] ]

      @mocks.each(&:verify)
    end

    it "should raise on missing target" do
      double = @double_class.new 34, nil

      expect(proc do
        @subject.remove_bulk([ double ])
      end).must_raise IndexError

      @mocks.each(&:verify)
    end
  end

  describe "#remove_all" do
    before do
      @subject = RGame::Common::CollectionEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "add" ]
        m.expect :emit, nil, [ "remove" ]
        m.expect :parent=, nil, [ nil ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @subject.add_bulk(@children)
    end

    it "should remove all" do
      @subject.remove_all
      expect(@subject.children).must_equal []

      @mocks.each(&:verify)
    end
  end

  describe "#inspect" do
    before do
      @subject = RGame::Common::CollectionEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "add" ]
        m.expect :inspect, ("<mock %i>" % (i + 1)), []
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @subject.add_bulk(@children)
    end

    it "should format self" do
      expect(@subject.inspect).must_equal(<<-STR % @subject.id)
#<RGame::Common::CollectionEntity id=%i active=true>
  <mock 1>
  <mock 2>
  <mock 3>
      STR

      @mocks.each(&:verify)
    end
  end

  describe "#last" do
    before do
      @subject = RGame::Common::CollectionEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "add" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @subject.add_bulk(@children)
    end

    it "should emit to children" do
      @mocks.each do |e|
        e.expect :emit, nil, [ "foo", "bar" ]
      end
      expect(@subject.emit "foo", "bar").must_be :nil?

      @mocks.each(&:verify)
    end

    it "should not emit new to children" do
      expect(@subject.emit "new", "bar").must_be :nil?

      @mocks.each(&:verify)
    end
  end
end
