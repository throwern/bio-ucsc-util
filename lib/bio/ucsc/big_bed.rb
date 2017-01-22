# == big_bed.rb
# This file contains the BigBed class
#
# == Contact
#
# Author::    Nicholas A. Thrower
# Copyright:: Copyright (c) 2017 Nicholas A Thrower
# License::   See LICENSE.txt for more details
#

# :nodoc:
module Bio
  module Ucsc
    # The BigWig class interacts with bigWig files
    class BigBed
      require 'bio/ucsc/binding'
      # bigWig file name
      attr_accessor :filename
      # pointer to bbiFile
      attr_accessor :bbi_file
      # convenience method to create a new BigBed and open it.
      def self.open(*args)
        self.new(*args).open
      end
      # Returns a new BigBed.
      def initialize(f=nil, opts={})
        @filename = f
        return self
      end
      # opens the file
      def open
        raise ArgumentError, "filename undefined" unless filename
        raise NameError, "#{filename} not found" unless File.exist?(filename)
        raise LoadError, "#{filename} bad format" unless Binding::bigBedFileCheckSigs(filename)
        Binding::udcSetDefaultDir Binding::udcDefaultDir 
        @bbi_file = Binding::bigBedFileOpen(filename)
        return self
      end
      # closes the file
      def close
        if bbi_file
          bbi_ptr= FFI::MemoryPointer.new(:pointer)
          bbi_ptr.write_pointer(bbi_file)
          Binding::bbiFileClose(bbi_ptr)
        end
        @bbi_file = nil
      end
      
      def count
        Binding::bigBedItemCount(bbi_file)
      end
      
      # retrieves intervals from the bigBed for the given range.
      # - chrom  => Sequence name for summary
      # - start  => Start of range (0 based)
      # - stop  => End of range
      # hash Options:
      # * :count  => Max number of items to return (0 for all)
      def interval(chrom, start, stop, opts={})
        count = opts[:count]||0
        # create the local memory pool
        lm = FFI::Pointer.new(Binding::lmInit(0))
        # Get the first interval
        bb_interval = Binding::bigBedIntervalQuery(bbi_file, chrom, start, stop, count, lm)
        # copy data to ruby array
        a = []
        bbi = Binding::BigBedInterval.new(bb_interval)
        a << bbi
        while bbi = bbi.next
          a << bbi
        end
        # Clear C memory
        Binding::LmPointerHelper.release(lm)
        return a
      end  
      
    end
  end
end