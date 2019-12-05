require "rgame/common/stack_entity"

describe RGame::Common::StackEntity do
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

  describe "#push" do
    it "should push children" do
      subject = RGame::Common::StackEntity.new

      mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ subject ]
        m.expect :emit, nil, [ "push" ]
        m
      end

      children = mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      children.each { |e| subject.push(e) }

      expect(subject.children).must_equal children

      mocks.each { |e| e.verify }
    end
  end

  describe "#create" do
    it "should make and push entity" do
      subject = RGame::Common::StackEntity.new "_ctx_"

      mock_1 = Minitest::Mock.new
      mock_1.expect :parent=, nil, [ subject ]
      mock_1.expect :emit, nil, [ "push" ]

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

  describe "#pop" do
    before do
      @subject = RGame::Common::StackEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "push" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @children.each(&@subject.method(:push))
    end

    it "should remove last" do
      @mocks[2].expect :emit, nil, [ "pop" ]
      @mocks[2].expect :parent=, nil, [ nil ]

      @subject.pop
      expect(@subject.children).must_equal @children.dup.tap { |o| o.pop }

      @mocks.each(&:verify)
    end
  end

  describe "#swap" do
    before do
      @subject = RGame::Common::StackEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "push" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @children.each(&@subject.method(:push))
    end

    it "should remove last and push" do
      @mocks[2].expect :emit, nil, [ "pop" ]
      @mocks[2].expect :parent=, nil, [ nil ]

      mock = Minitest::Mock.new
      mock.expect :parent=, nil, [ @subject ]
      mock.expect :emit, nil, [ "push" ]

      double = @double_class.new(37, mock)

      @subject.swap double
      expect(@subject.children).must_equal(@children.dup.tap do |o|
        o.pop
        o.push(double)
      end)

      (@mocks + [ mock ]).each(&:verify)
    end
  end

  describe "#last" do
    before do
      @subject = RGame::Common::StackEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "push" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @children.each(&@subject.method(:push))
    end

    it "should emit to children" do
      @mocks.last.expect :emit, nil, [ "foo", "bar" ]
      expect(@subject.emit "foo", "bar").must_be :nil?

      @mocks.each(&:verify)
    end

    it "should not emit new to children" do
      expect(@subject.emit "new", "bar").must_be :nil?

      @mocks.each(&:verify)
    end
  end
end
