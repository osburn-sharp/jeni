#
#
# = Jeni
#
# == Optparse
#
# Author:: Robert Sharp
# Copyright:: Copyright (c) 2012 Robert Sharp
# License:: Open Software Licence v3.0
#
# This software is licensed for use under the Open Software Licence v. 3.0
# The terms of this licence can be found at http://www.opensource.org/licenses/osl-3.0.php
# and in the file copyright.txt. Under the terms of this licence, all derivative works
# must themselves be licensed under the Open Software Licence v. 3.0
#
# 
#
require 'optparse'

module Jeni
  
  # Mixin included in {Jeni::Installer} that adds optparse option processing.
  module Optparse
    
    # enables command line options to be processed directly. These correspond to the
    # options in {Jeni::Options}.
    #
    # For example:
    #
    #    Jeni::Installer.new_from_gem('jeni') do |jeni|
    #      jeni.optparse(ARGV)
    #      jeni.file(source, target)
    #    end.run!
    #
    def optparse(args)
      opts = OptionParser.new
      
      opts.banner = "Usage: #{$0} [options]"
      opts.separator ''
      opts.separator '  a post-install script to use with a gem after the main installation'
      opts.separator '  in order to copy files etc where gem cannot reach.'
      opts.separator ''
      
      opts.on('-p', '--pretend', 'pretend to take actions but do nothing really') do
        @pretend = true
      end
      
      opts.on('-a', '--answer', 'allow questions to be answered in pretend mode') do
        @answer = true
      end
      
      opts.on('-v', '--verbose', 'increase the messages produced to help with problems') do
        @verbose = true
      end
      
      opts.on('-q', '--quiet', 'suppress all output') do
        @quiet = true
      end
      
      opts.on('-n', '--nodir', 'do not make any subdirectories if they do not already exist') do
        @nomkdir = true
      end
      
      opts.on('-o', '--owner [NAME]', String, 'specify the default owner for installed files') do |o|
        @owner = o
      end
      
      opts.on('-g', '--group [NAME]', String, 'specify the default group for installed files') do |g|
        @group = g
      end
      
      opts.on_tail('-h', '--help', 'you are looking at it') do
        puts opts
        exit 0
      end
      
      opts.parse!(args)
      
      @answer = false unless @pretend
      
    end
    
  end
end
