#
#
# = Jeni::Options
#
# == Options module for the Jeni Installer
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

module Jeni
  
  # Mixin included in {Jeni::Installer} that sets options for running the installer. 
  module Options
    
    # show what would happen but do not actually install anything
    # @param [Boolean] bool set to true to select option
    def pretend(bool=true)
      @pretend = bool
    end
    
    # allow answers to questions when pretending
    # @param [Boolean] bool set to true to select option
    def answer(bool=true)
      @answer = bool
    end
    
    # provide additional messages to assist in debugging issues
    # @param [Boolean] bool set to true to select option
    def verbose(bool=true)
      @verbose = bool
    end
    
    # suppress all messages
    # @param [Boolean] bool set to true to select option
    def quiet(bool=true)
      @quiet = bool
    end
    
    # do not attempt to create directories that do not exist
    # @param [Boolean] bool set to true to select option
    def nomkdir(bool=true)
      @nomkdir = bool
    end
    
    # set the default owner for all files
    # @param [String] user to set as the default owner
    def owner(user)
      @owner = user
    end
    
    # set the default group for all files
    # @param [String] group to set as the default
    def group(group)
      @group = group
    end
    
    # set the default target root to /usr instead of /usr/local
    def usr
      @target_root = '/usr/'
    end
    
    # set the default target root to the value given
    def target=(path)
      @target_root = path
    end
    
    # set the shebang in wrappers to use env (e.g. /usr/bin/env)
    def env_shebang(bool=true)
      @env_shebang = bool
    end
    
  end
  
end