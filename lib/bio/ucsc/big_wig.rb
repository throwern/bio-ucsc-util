# == big_wig.rb
# This file contains the BigWig class
#
# == Contact
#
# Author::    Nicholas A. Thrower
# Copyright:: Copyright (c) 2012 Nicholas A Thrower
# License::   See LICENSE.txt for more details
#

# :nodoc:
module Bio
  module Ucsc
    # The BigWig class interacts with bigWig files
    class BigWig
      require 'bio/ucsc/binding'
      # bigWig file name
      attr_accessor :filename
      # pointer to bbiFile
      attr_accessor :bbi_file
      # convenience method to create a new BigWig and open it.
      def self.open(*args)
        self.new(*args).open
      end
      # Returns a new BigWig.
      def initialize(f=nil, opts={})
        @filename = f
        return self
      end
      # opens the file
      def open
        raise ArgumentError, "filename undefined" unless filename
        raise NameError, "#{filename} not found" unless File.exist?(filename)
        raise LoadError, "#{filename} bad format" unless Binding::isBigWig(filename)
        @bbi_file = Binding::bigWigFileOpen(filename)
        return self
      end
      # closes the file
      def close
        Binding::bbiFileClose(bbi_file) if bbi_file
        @bbi_file = nil
      end
      # returns the caclulated standard deviation
      def std_dev(chrom=nil,opts={})
        if(chrom)
          self.summary(chrom,0,self.chrom_length(chrom),1,{type:'std'}).first
        else
          bwf,bbi_sum = prepare_bwf(opts)
          return Binding::calcStdFromSums(bbi_sum[:sumData], bbi_sum[:sumSquares], bbi_sum[:validCount])
        end
      end
      # Percent of bases in region containing actual data
      def coverage(chrom=nil,opts={})
        if(chrom)
          self.summary(chrom,0,self.chrom_length(chrom),1,{type:'coverage'}).first
        else
          bwf,bbi_sum = prepare_bwf(opts)          
          return bbi_sum[:validCount] / chrom_length.to_f
        end
      end
      # Returns the minimum value of items
      def min(chrom=nil,opts={})
        if(chrom)
          self.summary(chrom,0,self.chrom_length(chrom),1,{type:'min'}).first
        else
          bwf,bbi_sum = prepare_bwf(opts)
          return bbi_sum[:minVal]
        end
      end
      # Returns the maximum value of items
      def max(chrom=nil,opts={})
        if(chrom)
          self.summary(chrom,0,self.chrom_length(chrom),1,{type:'max'}).first
        else
          bwf,bbi_sum = prepare_bwf(opts)
          return bbi_sum[:maxVal]
        end
      end
      # Returns the mean value of items
      def mean(chrom=nil,opts={})
        if(chrom)
          self.summary(chrom,0,self.chrom_length(chrom),1,{type:'mean'}).first
        else
          bwf,bbi_sum = prepare_bwf(opts)
          return bbi_sum[:sumData]/bbi_sum[:validCount].to_f
        end
      end
      # Total bases containing actual data
      def bases_covered(opts={})
        bwf,bbi_sum = prepare_bwf(opts)
        return bbi_sum[:validCount]
      end
      # Returns size of given chromosome or the sum of all chromosomes
      def chrom_length(chrom=nil)
        chrom.nil? ? chrom_list.inject(0){|sum,chrom|sum+=chrom[:size]} : Binding::bbiChromSize(bbi_file,chrom)
      end
      # prints details about the file:
      # - minMax/m => Only output the minimum and maximum values
      # - zooms/z  => Display zoom level details
      # - chroms/c => Display chrom details
      # - udcDir/u => /dir/to/cache - place to put cache for remote bigBed/bigWigs
      def info(opts={})
        min_max =opts[:m] ||= opts[:minMax]
        zooms =opts[:z] ||= opts[:zooms]
        chroms =opts[:c] ||= opts[:chroms]
        bwf,bbi_sum = prepare_bwf(opts)
        # print min/max
        if(min_max)
          printf "%f %f\n", bbi_sum[:minVal], bbi_sum[:maxVal]
          return
        end
        # start summary        
        printf "version: %d\n", bwf[:version]
        printf "isCompressed: %s\n", (bwf[:uncompressBufSize] > 0 ? "yes" : "no")
        printf "isSwapped: %i\n", bwf[:isSwapped] ? 1 : 0
        printf "primaryDataSize: %i\n",bwf[:unzoomedIndexOffset] - bwf[:unzoomedDataOffset]
        unless(bwf[:levelList].null?)
          list = Binding::BbiZoomLevel.new(bwf[:levelList])
          printf "primaryIndexSize: %i\n", list[:dataOffset] - bwf[:unzoomedIndexOffset]
        end
        # print zoom level details
        printf "zoomLevels: %d\n", bwf[:zoomLevels]
        if(zooms)
          zoom = Binding::BbiZoomLevel.new(bwf[:levelList])
          while !zoom.null?
            printf "\t%d\t%d\n", zoom[:reductionLevel], zoom[:indexOffset] - zoom[:dataOffset]
            zoom = zoom[:next]
          end
        end
        # print chrom details
        
        printf "chromCount: %d\n", chrom_list.size
        if(chroms)
          chrom_list.each do |chrom|
            printf "\t%s %d %d\n", chrom[:name], chrom[:id], chrom[:size]
          end
        end
        # finish summary
        printf "basesCovered: %i\n", bbi_sum[:validCount]
        printf "mean: %f\n", bbi_sum[:sumData]/bbi_sum[:validCount]
        printf "min: %f\n", bbi_sum[:minVal]
        printf "max: %f\n", bbi_sum[:maxVal]
        printf "std: %f\n", Binding::calcStdFromSums(bbi_sum[:sumData], bbi_sum[:sumSquares], bbi_sum[:validCount])
        return 
      end
      # retrieves summary information from the bigWig for the given range.
      # - chrom  => Sequence name for summary
      # - start  => Start of range (0 based)
      # - stop  => End of range
      # - count  => Number of datapoints to compute (1 for simple summary)
      # hash Options:
      # * :udcDir - /dir/to/cache - place to put cache for remote bigBed/bigWigs
      # * :type => Summary type string
      # * * mean - average value in region (default)
      # * * min - minimum value in region
      # * * max - maximum value in region
      # * * std - standard deviation in region
      # * * coverage - %% of region that is covered
      def summary(chrom, start, stop, count, opts={})
        type = opts[:type] || opts[:t] || 'mean'
        udc_dir = opts[:u] ||= opts[:udcDir] ||= Binding::udcDefaultDir()
        Binding::udcSetDefaultDir(udc_dir)
        # allocate the array
        summaryValues = FFI::MemoryPointer.new(:double,count)
        # initialize to all 'NaN'
        summaryValues.write_array_of_type(:double,:write_string,["NaN"]*count)
        # fill in with Summary Data
        Binding::bigWigSummaryArray(bbi_file, chrom, start, stop, Binding::bbiSummaryTypeFromString(type),count,summaryValues)
        return summaryValues.read_array_of_double(count)
      end      
      # creates a new smoothed bigWig file at the supplied location. Smoothing options:
      # - chrom => restrict smoothing to a given chromosome
      # - cutoff => probe count cutoff[median]
      # - window => rolling window size
      # - type => smoothing algorithm [avg]
      # * * 'avg' - average depth in window
      # * * 'probe' - count of regions (probes) crossing 'cutoff' in window
      # Big Wig options:
      # - :blockSize => Number of items to bundle in r-tree [256]
      # - :itemsPerSlot => Number of data points bundled at lowest level [1024]
      # - :unc => If set, do not use compression
      # - :udcDir => /dir/to/cache - place to put cache for remote bigBed/bigWigs
      def smooth(out_file,opts={})
        verb = opts[:v] || 0
        window = opts[:window] || 250
        cutoff = opts[:cutoff] || self.mean
        block_size = opts[:block_size]||256
        chrom = opts[:chrom]||nil
        items_per_slot = opts[:items_per_slot]||1024
        unc = opts[:unc]||false
        do_compress = !unc
        type = opts[:type]||'avg'
        udc_dir = opts[:u] ||= opts[:udcDir] ||= Binding::udcDefaultDir()
        Binding::bigWigFileSmooth(filename, chrom, block_size, items_per_slot, do_compress, window, verb, out_file, type, cutoff)
      end
      
      private
      # configures the temporary directory in case of remote files and returns a new BbiFile Struct and BbiSummaryElement
      def prepare_bwf(opts)
        udc_dir = opts[:u] ||= opts[:udcDir] ||= Binding::udcDefaultDir()
        Binding::udcSetDefaultDir(udc_dir)     
        return Binding::BbiFile.new(bbi_file), Binding::bbiTotalSummary(bbi_file)
      end
      # returns an array of BbiChromInfo items in file
      def chrom_list
        chrom = Binding::BbiChromInfo.new(Binding::bbiChromList(bbi_file))        
        a = []
        while !chrom.null?
          a << chrom
          chrom = chrom[:next]
        end
        return a
      end
    end
  end
end