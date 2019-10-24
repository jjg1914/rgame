require "rgame/core/events"

describe RGame::Core::Events do
  describe RGame::Core::Events::ModifierState do
    before do
      @subject = RGame::Core::Events::ModifierState.new
    end

    describe "#ctrl" do
      it "should be false" do
        expect(@subject.ctrl).must_equal false
      end

      it "should be true when left ctrl true" do
        @subject.left_ctrl = true
        expect(@subject.ctrl).must_equal true
      end

      it "should be true when right ctrl true" do
        @subject.left_ctrl = true
        expect(@subject.ctrl).must_equal true
      end

      it "should be true when left and right ctrl true" do
        @subject.left_ctrl = true
        @subject.right_ctrl = true
        expect(@subject.ctrl).must_equal true
      end
    end

    describe "#shift" do
      it "should be false" do
        expect(@subject.shift).must_equal false
      end

      it "should be true when left shift true" do
        @subject.left_shift = true
        expect(@subject.shift).must_equal true
      end

      it "should be true when right shift true" do
        @subject.left_shift = true
        expect(@subject.shift).must_equal true
      end

      it "should be true when left and right shift true" do
        @subject.left_shift = true
        @subject.right_shift = true
        expect(@subject.shift).must_equal true
      end
    end

    describe "#alt" do
      it "should be false" do
        expect(@subject.alt).must_equal false
      end

      it "should be true when left alt true" do
        @subject.left_alt = true
        expect(@subject.alt).must_equal true
      end

      it "should be true when right alt true" do
        @subject.left_alt = true
        expect(@subject.alt).must_equal true
      end

      it "should be true when left and right alt true" do
        @subject.left_alt = true
        @subject.right_alt = true
        expect(@subject.alt).must_equal true
      end
    end

    describe "#super" do
      it "should be false" do
        expect(@subject.super).must_equal false
      end

      it "should be true when left super true" do
        @subject.left_super = true
        expect(@subject.super).must_equal true
      end

      it "should be true when right super true" do
        @subject.left_super = true
        expect(@subject.super).must_equal true
      end

      it "should be true when left and right super true" do
        @subject.left_super = true
        @subject.right_super = true
        expect(@subject.super).must_equal true
      end
    end
  end
end
