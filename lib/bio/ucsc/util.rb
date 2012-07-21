# == ucsc_util.rb
# This file contains the UcscUtil class implementing the ucsc utility programs
#
# == Contact
#
# Author::    Nicholas A. Thrower
# Copyright:: Copyright (c) 2012 Nicholas A Thrower
# License::   See LICENSE.txt for more details

# :nodoc:
module Bio 
# -
  module Ucsc
    class Util
      # UcscUtil implements the utility programs from the ucsc source as class methods.
      # Names are converted by ruby convention to snake case (underscore) based on the camel case C routines
      require 'bio/ucsc/binding'
      # Converts ascii Wig file to binary BigWig
      # - :wig_file => input wiggle file
      # - :chrom_file => two column file: <chromosome name> <size in bases> for each entry
      # - :big_wig_file => output indexed file
      # Options:
      # * :blockSize => Number of items to bundle in r-tree [256]
      # * :itemsPerSlot => Number of data points bundled at lowest level [1024]
      # * :clip => If set just issue warning messages rather than dying if wig file contains items off end of chromosome
      # * :unc => If set, do not use compression    
      def self.wig_to_big_wig(wig_file, chrom_file, big_wig_file, opts={})
        block_size = opts[:block_size]||256
        items_per_slot = opts[:items_per_slot]||1024
        clip = opts[:clip]||false
        unc = opts[:unc]||false
        do_compress = !unc
        Binding::bigWigFileCreate(wig_file,chrom_file,block_size,items_per_slot,clip,do_compress,big_wig_file)
        return BigWig.open(big_wig_file)
      end   
      # Converts ascii bedGraph file to binary bigWig.
      # The input bedGraph file must be sorted, use the unix sort command:
      #   sort -k1,1 -k2,2n unsorted.bedGraph > sorted.bedGraph
      # - :bed_file => input bedGraph
      # - :chrom_file => two column file: <chromosome name> <size in bases> for each entry
      # - :big_wig_file => output indexed file
      def self.bed_graph_to_big_wig(wig_file, chrom_file, big_wig_file, opts={})
        block_size = opts[:block_size]||256
        items_per_slot = opts[:items_per_slot]||1024
        unc = opts[:unc]||false
        do_compress = !unc
        Binding::bedGraphToBigWig(wig_file,chrom_file,block_size,items_per_slot,do_compress,big_wig_file)
        return BigWig.open(big_wig_file)
      end
    end
  end
end