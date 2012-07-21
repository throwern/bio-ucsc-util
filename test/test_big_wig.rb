require 'helper'

class TestBioUcscUtil < Test::Unit::TestCase
  include Bio::Ucsc
  TEST_BW = "test/1.bw"
  TEST_WIG = "test/1.wig"
  TEST_BED = "test/1.bed"
  TEST_WIG_OUT = "test/1.wig.bw"
  TEST_BED_OUT = "test/2.bed.bw"
  CHROM_FILE = "test/chrom.sizes"
  BAD_FILE = 'test/not_existing_file'
  TEST_SMOOTH_FILE = 'test/1_smoothed.bw'
  TEST_SMOOTH_OUT_FILE = 'test/smoothed.bw'
  
  context "a new big wig" do
    setup do
      @bw = BigWig.new
    end
    should "not be open and have no filename" do
      assert_equal nil, @bw.bbi_file
      assert_equal nil, @bw.filename
    end
    should "allowing setting filename" do
      @bw.filename = TEST_BW
      assert_equal TEST_BW, @bw.filename
    end
    should "report no filename on open" do
      assert_raise ArgumentError do
        @bw.open
      end
    end
    should "report bad filename on open" do
      @bw.filename = BAD_FILE
      assert_raise NameError do
        @bw.open
      end
    end
    should "report bad format on open" do
      @bw.filename = TEST_BED
      assert_raise LoadError do
        @bw.open
      end
    end
    should "allow opening a good file" do
      @bw.filename = TEST_BW
      assert_nothing_raised do 
        @bw.open
      end
      assert_not_nil @bw.bbi_file
    end
  end
  
  context "an open big wig" do 
    setup do
      @bw = BigWig.open(TEST_BW)
      @out = StringIO.new
      $stdout = @out
    end
    should "already be open" do 
      assert_not_nil @bw.bbi_file
    end
    should "allow closing a file" do
      @bw.close
      assert_nil @bw.bbi_file
    end
    should "have detailed info" do
      @bw.info
      assert_equal "version: 4\nisCompressed: no\nisSwapped: 0\nprimaryDataSize: 116\nprimaryIndexSize: 6204\nzoomLevels: 1\nchromCount: 1\nbasesCovered: 7\nmean: 52.857143\nmin: 10.000000\nmax: 100.000000\nstd: 36.839420\n", @out.string
    end
    should "allow chrom details" do
      @bw.info({:chroms => true})
      assert @out.string=~/chr1 0 5000/
    end
    should "allow zoom details" do
      @bw.info({:zooms => true})
      assert @out.string=~/32	36/
    end
    should "allow min/max" do
      @bw.info({:minMax => true})
      assert_equal "10.000000 100.000000\n", @out.string
    end
  end
  
  context "a new big wig from wig" do
    setup do
      @bw = Util.wig_to_big_wig(TEST_WIG,CHROM_FILE,TEST_WIG_OUT)
    end
    should "have summary data" do
      assert_same_elements( [5.0,10.0], @bw.summary("chr1",2,4,2,{:type => 'max'}) )
    end
    should "have min 1.0" do
      assert_equal 1.0, @bw.min
    end
    should "have max 10.0" do 
      assert_equal 10.0, @bw.max
    end
    should "have std of 2.94.." do
      assert_equal 2.9480801329998196, @bw.std_dev
    end
    should "have a mean of 4.23.." do
      assert_equal 4.235294117647059, @bw.mean
    end
    should "have 17 bases covered" do
      assert_equal 17, @bw.bases_covered
    end
    should "have total chromosome length of 17500" do
      assert_equal 17500, @bw.chrom_length
    end
    should "have total coverage of" do
      assert_equal 0.0009714285714285714, @bw.coverage
    end
    should "have chr1 length of" do
      assert_equal 5000, @bw.chrom_length('chr1')
    end
    should "have chr1 coverage of" do
      assert_equal 0.0014, @bw.coverage('chr1')
    end
    should "have chr2 min of 2" do
      assert_equal 2, @bw.min('chr2')
    end
    should "have chr2 max of 8" do
      assert_equal 8, @bw.max('chr2')
    end
    should "have chr2 mean of 5.0" do
      assert_equal 5.0, @bw.mean('chr2')
    end
    should "have chr3 std of 1.0" do
      assert_equal 1.0, @bw.std_dev('chr3')
    end
    should "allow smoothing" do
      assert_nothing_raised do
        @bw.smooth(TEST_SMOOTH_OUT_FILE)
      end
      `rm #{TEST_SMOOTH_OUT_FILE}`
    end
    teardown do
      `rm #{TEST_WIG_OUT}`
    end
  end
  
  context "a new big wig from bed" do
    setup do
      @bw = Util.bed_graph_to_big_wig(TEST_BED,CHROM_FILE,TEST_BED_OUT)
    end
    should "have summary data" do
      assert_same_elements [5.0,10.0], @bw.summary("chr1",3,5,2,{:type => 'max'})
    end
    should "have min 1.0" do
      assert_equal 1.0, @bw.min
    end
    should "have max 10.0" do 
      assert_equal 10.0, @bw.max
    end
    should "have chr2 length of 2500" do
      assert_equal 2500, @bw.chrom_length('chr2')
    end
    teardown do
      `rm #{TEST_BED_OUT}`
    end
  end

end
