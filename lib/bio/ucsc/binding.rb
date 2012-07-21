# == binding.rb
# This file contains the ffi binding declarations for the ucsc api
# See https://github.com/ffi/ffi
#
# == Contact
#
# Author::    Nicholas A. Thrower
# Copyright:: Copyright (c) 2012 Nicholas A Thrower
# License::   See LICENSE.txt for more details
#

# :nodoc:
module Bio
  # -
  module Ucsc
    # Ruby binding for the ucsc utils
    module Binding # :nodoc: all
      require 'bio/ucsc/library'
      extend FFI::Library
      ffi_lib Bio::Ucsc::Library.filename
      
      # CLASSES
      
      # A zoom level in bigWig file
      class BbiZoomLevel < FFI::Struct
        layout(
          :next_ptr, :pointer,            # Next in list
          :reductionLevel, :uint,         # How many bases per item
          :reserved, :uint,               # Zero for Now
          :dataOffset, :ulong_long,       # Offset of data for this level in file
          :indexOffset, :ulong_long       # Offset of index for this level in file
        )
        # allow for nested self referential *next pointer
        def [](value)
          if value==:next
            BbiZoomLevel.new(self[:next_ptr])
          else
            super(value)
          end
        end
      end
      
      # An open binary file (BigWig/BigBed)
      class BbiFile < FFI::Struct
        layout(
            :next, :pointer,                  # Next in list.
            :fileName, :string,               # Name of file - for better error reporting.
            :udc, :pointer,                   # Open UDC file handle.
            :typeSig, :uint,                  # bigBedSig or bigWigSig for now.
            :isSwapped, :bool,                # If TRUE need to byte swap everything.
            :chromBpt, :pointer,              # Index of chromosomes.
            :version, :ushort,                # Version number - initially 1.
            :zoomLevels, :ushort,             # Number of zoom levels.
            :chromTreeOffset, :ulong_long,    # Offset to chromosome index.
            :unzoomedDataOffset, :ulong_long, # Start of unzoomed data.
            :unzoomedIndexOffset, :ulong_long,# Start of unzoomed index.
            :fieldCount, :ushort,             # Number of columns in bed version.
            :definedFieldCount, :ushort,      # Number of columns using bed standard definitions.
            :asOffset, :ulong_long,           # Offset to embedded null-terminated AutoSQL file.
            :totalSummaryOffset, :ulong_long, # Offset to total summary information if any.  (On older files have to calculate)
            :uncompressBufSize, :uint,        # Size of uncompression buffer, 0 if uncompressed
            :unzoomedCir, :pointer,           # Unzoomed data index in memory - may be NULL.
            :levelList, :pointer              # List of zoom levels.
        )
      end
      
      # A BbiFile summary element
      class BbiSummaryElement < FFI::Struct
        layout(
        :validCount,:ulong_long,
        :minVal, :double,
        :maxVal, :double,
        :sumData, :double,
        :sumSquares, :double
        )
      end
      
      # Pair of a name and a 32-bit integer. Used to assign IDs to chromosomes.
      class BbiChromInfo < FFI::Struct
        layout(
        :next_ptr, :pointer,
        :name, :string,         # Chromosome name
        :id, :uint,             # Chromosome ID - a small number usually
        :size, :uint)           # Chromosome size in bases
        # allow for nested self referential *next pointer
        def [](value)
          if value==:next
            BbiChromInfo.new(self[:next_ptr])
          else
            super(value)
          end
        end
      end
      
      ## ENUMS
      
      # bbiSummaryType - way to summarize data
      BbiSummaryType = enum(:bbiSumMean, 0,
        :bbiSumMax,
        :bbiSumMin,
        :bbiSumCoverage,
        :bbiSumStandardDeviation
      )

      # FUNCTIONS
      # bbi
      attach_function :bbiChromList, [:pointer], :pointer                                                     # *bbiFile ; BbiChromInfo*
      attach_function :bbiChromSize, [:pointer,:pointer], :int32                                              # *bbiFile, chrom ; size
      attach_function :bbiFileClose, [:pointer], :void                                                        # *bbiFile
      attach_function :bbiTotalSummary, [:pointer], BbiSummaryElement.by_value                                # **bbiFile
      attach_function :bbiSummaryTypeFromString, [:string], BbiSummaryType                                    # summaryType
      # bigwig
      attach_function :bigWigFileCreate, [:string,:string,:int,:int,:bool,:bool,:string], :void                         # inName, chromSizes, blockSize, itemsPerSlot, clipDontDie, doCompress, outName      
      attach_function :bigWigFileOpen, [:string], :pointer                                                              # filename
      attach_function :bigWigFileSmooth, [:string, :string, :int, :int,:bool,:int,:int,:string,:string,:double], :void  # inName, chromSizes, blockSize, itemsPerSlot, doCompress, window, verbosity, outName, smoothType, Cutoff
      attach_function :bigWigSummaryArray, [:pointer,:pointer,:uint32,:uint32,BbiSummaryType,:int,:pointer], :bool      # *bbiFile, chrom, start, end, type, size, &values
      attach_function :isBigWig, [:string], :bool                                                                       # filename
      # utils
      attach_function :bedGraphToBigWig, [:string, :string, :int, :int, :bool, :string], :void                # inName, chromSizes, outName
      # udc
      attach_function :udcDefaultDir, [], :string
      attach_function :udcSetDefaultDir, [:string], :void                                                     # path
      # hmmstats
      attach_function :calcStdFromSums, [:double, :double, :uint64], :double                                  # sum, sumSquares, n 
      attach_function :slCount, [:pointer], :int                                                              # *bbiChromList
    end
  end
end