require "rgame/common/queue_entity"

describe RGame::Common::QueueEntity do
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

  describe "#enqueue" do
    it "should enqueue children" do
      subject = RGame::Common::QueueEntity.new

      mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ subject ]
        m.expect :emit, nil, [ "enqueue" ]
        m
      end

      children = mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      children.each { |e| subject.enqueue(e) }

      expect(subject.children).must_equal children

      mocks.each { |e| e.verify }
    end
  end

  describe "#create" do
    it "should make and enqueue entity" do
      subject = RGame::Common::QueueEntity.new "_ctx_"

      mock_1 = Minitest::Mock.new
      mock_1.expect :parent=, nil, [ subject ]
      mock_1.expect :emit, nil, [ "enqueue" ]

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

  describe "#dequeue" do
    before do
      @subject = RGame::Common::QueueEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "enqueue" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @children.each(&@subject.method(:enqueue))
    end

    it "should remove last" do
      @mocks[0].expect :emit, nil, [ "dequeue" ]
      @mocks[0].expect :parent=, nil, [ nil ]

      @subject.dequeue
      expect(@subject.children).must_equal @children.dup.tap { |o| o.shift }

      @mocks.each(&:verify)
    end
  end

  describe "#last" do
    before do
      @subject = RGame::Common::QueueEntity.new

      @mocks = 3.times.map do |i|
        m = Minitest::Mock.new
        m.expect :parent=, nil, [ @subject ]
        m.expect :emit, nil, [ "enqueue" ]
        m
      end

      @children = @mocks.each_with_index.map do |e, i|
        @double_class.new(i + 1, e)
      end

      @children.each(&@subject.method(:enqueue))
    end

    it "should emit to children" do
      @mocks.first.expect :emit, nil, [ "foo", "bar" ]
      expect(@subject.emit "foo", "bar").must_be :nil?

      @mocks.each(&:verify)
    end

    it "should not emit new to children" do
      expect(@subject.emit "new", "bar").must_be :nil?

      @mocks.each(&:verify)
    end
  end
end
