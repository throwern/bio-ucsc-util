#(c) Copyright 2012 Nicholas A Thrower. All Rights Reserved.
# create Rakefile for shared library compilation

path = File.expand_path(File.dirname(__FILE__))

path_external = File.join(path, "../../lib/bio/ucsc/src/")

version = File.open(File.join(path_external,"Version"),'r')
Version = version.read
version.close

Source = "ucsc-util-src-#{Version}.tgz"

File.open(File.join(path,"Rakefile"),"w") do |rakefile|
rakefile.write <<-RUBY
require 'rbconfig'
require 'fileutils'
include FileUtils::Verbose
require 'rake/clean'

task :prepare do 
  sh "tar xzvf #{Source}"
  cp("makefile","ucsc-util-src-#{Version}/lib")
end

task :compile do
  # build libraries
  cd("ucsc-util-src-#{Version}/lib") do
    sh "make"
    case Config::CONFIG['host_os']
      when /linux/
        sh "make libucsc.so.1"
        cp("libucsc.so.1","#{path_external}")
      when /darwin/
        sh "make libucsc.1.dylib"
        cp("libucsc.1.dylib","#{path_external}")
      else raise NotImplementedError, "ucsc-util not supported on your platform"
    end
    cp("libucsc.a","#{path_external}")
  end
end

task :clobber do
  rm_f("#{path_external}libucsc.a")
  rm_f("#{path_external}libucsc.so.1")
  rm_f("#{path_external}libucsc.1.dylib")
end

task :clean do
  rm_rf("ucsc-util-src-#{Version}")
end

desc "clean compile"
task :make_clean do
  cd("ucsc-util-src-#{Version}") do
    sh "make clean"
  end
end

task :default => [:prepare,:compile,:clean]
  
RUBY
  
end
