require 'helper'

class TestBigBed < Test::Unit::TestCase
  include Bio::Ucsc
  TEST_BED = "test/1.bed"
  TEST_BIG_BED_OUT = "test/1.bed.bb"
  TEST_BIG_BED = "test/1.bigbed"
  CHROM_FILE = "test/chrom.sizes"
  BAD_FILE = 'test/not_existing_file'
  
  context "a new big bed" do
    setup do
      @bb = BigBed.new
    end
    should "not be open and have no filename" do
      assert_equal nil, @bb.bbi_file
      assert_equal nil, @bb.filename
    end
    should "allow setting filename" do
      @bb.filename = TEST_BED
      assert_equal TEST_BED, @bb.filename
    end
    should "report no filename on open" do
      assert_raise ArgumentError do
        @bb.open
      end
    end
    should "report bad filename on open" do
      @bb.filename = BAD_FILE
      assert_raise NameError do
        @bb.open
      end
    end
    should "report bad format on open" do
      @bb.filename = CHROM_FILE
      assert_raise LoadError do
        @bb.open
      end
    end
    should "allow opening a good file" do
      @bb.filename = TEST_BIG_BED
      assert_nothing_raised do 
        @bb.open
      end
      assert_not_nil @bb.bbi_file
    end
  end
  
  context "an open big bed" do 
    setup do
      @bb = BigBed.open(TEST_BIG_BED)
      @out = StringIO.new
      $stdout = @out
    end
    should "already be open" do 
      assert_not_nil @bb.bbi_file
    end
    should "allow closing a file" do
      @bb.close
      assert_nil @bb.bbi_file
    end
    should "have count info" do
      assert_equal 12, @bb.count
    end
  end
  
  context "a new big bed from bed" do
    setup do
      @bb = Util.bed_to_big_bed(TEST_BED,CHROM_FILE,TEST_BIG_BED_OUT)
    end
    should "have count info" do
      assert_equal 12, @bb.count
    end
    should "have interval data" do
      assert_equal 7, @bb.interval("chr1",1,11).count
      assert_equal 5, @bb.interval("chr2",1,10).count
    end
    should "have intervals" do
      i1 = @bb.interval("chr1",1,10)
      c1_1 = i1.first
      c1_3 = i1.take(3).last
      i2 = @bb.interval("chr2",1,10)
      c2_1 = i2.first
      c2_last = i2.take(5).last
      
      assert_equal 1, c1_1[:start]
      assert_equal 2, c1_1[:end]
      assert_equal "1", c1_1[:rest]
      
      assert_equal 3, c1_3[:start]
      assert_equal 4, c1_3[:end]
      assert_equal "5", c1_3[:rest]
      
      assert_equal 1, c2_1[:start]
      assert_equal 2, c2_1[:end]
      assert_equal "1", c2_1[:rest]
      
      assert_equal 5, c2_last[:start]
      assert_equal 6, c2_last[:end]
      assert_equal "1", c2_last[:rest]
    end
  end
end