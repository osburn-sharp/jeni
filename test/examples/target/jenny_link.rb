#
# Author:: R.J.Sharp
# Email:: robert(a)osburn-sharp.ath.cx
# Copyright:: Copyright (c) 2012 
# License:: Open Software Licence v3.0
#
# This software is licensed for use under the Open Software Licence v. 3.0
# The terms of this licence can be found at http://www.opensource.org/licenses/osl-3.0.php
# and in the file LICENCE. Under the terms of this licence, all derivative works
# must themselves be licensed under the Open Software Licence v. 3.0
#
# 
# [requires go here]
require 'rubygems'

# = Jeni
#
# [Description of the main module]
module Jeni
  class Installer
    
    def initialize(gem_name)
      @gem_name = gem_name
      @gem_spec = Gem::Specification.find_by_name(@gem_name)
      @commands = []
    end
    
    def self.construct(gem_name, options={}, &block)
      @pretend = options[:pretend] || true # JUST FOR NOW!
      installer = self.new(gem_name)
      block.call(installer)
      return self
    end
    
    def run!(pretent=false)
      
    end
    
    # copy a file from the source, relative to the gem home to the target
    # which is absolute
    def file(source, target, opts={})
      @commands << {:file => {source => target}}
      if opts.has_key?(:chown) then
        @commands << {:chown => opts[:chown]}
      end
    end
    
    # copy all of the files in a directory
    def directory(source, target, opts={})
      
    end
    
    # create a wrapper at target to call source
    def wrapper(source, target)
      
    end
    
    def link(source, target)
      
    end
    
  end
end