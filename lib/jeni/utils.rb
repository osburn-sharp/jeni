#
#
# = Jeni::Utils
#
# == useful utilities to include in the main installer
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
require 'colored'
require 'diffy'
require 'rubygems' # legitimate cos this module uses Gem!
require 'haml'

module Jeni
  
  # mixin of underlying utilities that users do not need to know about. Tests are in
  # spec/jeni_utils_spec.rb
  module Utils
    
    
    # construct the path and 
    # check if file exists and create error if not
    def check_file(file)
      if file[0,1] == '/' then
        # absolute path so leave unaltered
      else
        file = File.expand_path(File.join(@source_root, file))
      end
      @errors[:missing] = file unless FileTest.exists?(file)
      return file
    end
    
    # check if target directory exists and is writeable
    # this will create a target if it does not exist (and all intermediate paths) unless
    # the nomkdir option is set
    def check_target(target, owner=nil)
      unless target[0,1] == '/' 
        target = File.expand_path(File.join(@target_root, target))
      end
      dir = File.dirname(target)
      unless FileTest.directory?(dir)
        unless @nomkdir 
          @commands << {:mkdir => dir}
          if owner then
            @commands << {:chown => {:file => dir, :owner => owner}}
          end
          return target
        end
        @errors[:missing] = dir 
      end
      @errors[:unwritable] = dir unless FileTest.writable?(dir)
      return target
    rescue
      @errors[:unwritable] = dir unless FileTest.writable?(dir)
      return target
    end
    
    # ensure this is called for a gem
    def check_gem(method)
      @errors[method] = "The source needs to be a gem" unless @gem
    end
    
    def check_executable(file)
      unless FileTest.executable?(file)
        @errors[:no_exec] = file
      end
    end
    
    # check if a given user exists (e.g. for changing ownership)
    def check_user(user)
      Etc.getpwnam(user)
    rescue ArgumentError
      @errors[:no_user] = "User does not exist: #{user}" unless @new_users.include?(user)
    end
    
    def check_group(group)
      Etc.getgrnam(group)
    rescue ArgumentError
      @errors[:group] = "Group does not exist: #{group}" unless @new_groups.include?(group)
    end
    
    # check there is no user
    def check_new_user(user, opts, skip)
      if opts.has_key?(:uid) then
        # check that it is not already in use
        begin
          Etc.getpwuid(opts[:uid])
          @errors[:user] = "Given uid is already in use: #{opts[:uid]}" unless skip
        rescue ArgumentError
          # no uid - so good
        end
      end
      if opts.has_key?(:gid) then
        # check the group DOES exist
        begin
          Etc.getgrgid(opts[:gid])
        rescue ArgumentError
          @errors[:user] = "Group id does not exist: #{opts[:gid]}"
          return
        end
      end
      Etc.getpwnam(user)
      # user exists, so ignore it
      @errors[:user] = "New user already exists: #{user}" unless skip
      return skip
    rescue ArgumentError
      # will get here if user does NOT exist  
      @new_users << user
      @new_groups << user if opts.has_key?(:user_group)
      return false # do not skip!
    end
    
    # check there is no group
    def check_new_group(group, opts, skip)
      if opts.has_key?(:gid) then
        # check that it is not already in use
        begin
          Etc.getgrgid(opts[:gid])
          @errors[:group] = "Given gid is already in use: #{opts[:gid]}" unless skip
        rescue ArgumentError
          # no uid - so good
        end
      end
      Etc.getgrnam(group)
      # user exists, so ignore it
      @errors[:group] = "New group already exists: #{group}" unless skip
      return skip
    rescue ArgumentError
      # will get here if user does NOT exist 
      @new_groups << group
      return false
    end
    
    # ensure user is root
    def check_root(skip)
      return false if skip
      @errors[:root] = "You do not have sufficient privileges for this operation" unless Process.uid == 0
    end

    # ensure the mode given is valid
    def check_chmod(mode)
      return unless mode #called with a nil mode
      if mode >= 512 || mode <= 0 then
        @errors[:invalid] = "mode: #{mode.to_s(8)}"
      end
    end
    
    # convert a filename etc to a proper class name
    # For example, converts 'my_service' to 'MyService'
    #
    # @param [String] string to convert to a classname
    # @return [String] converted classname
    def classify(string)
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
    end
    
    
    # helper to add commands for options
    def process_options(opts, target)
      owner = opts[:chown] || @owner
      group = opts[:chgrp] || @group
      chmod = opts[:chmod]
      if owner then
        check_user(owner)
        @commands << {:chown => {:owner => owner, :file => target}}
      end
      if group then
        check_group(group)
        @commands << {:chgrp => {:group => group, :file => target}}
      end
      @commands << {:chmod => {:file => target, :mode => chmod}} if chmod
      
    end
    
    # helper that shows if any errors have been reported
    def errors?
      ! @errors.empty?
    end
    
    # helper to process errors
    def each_error(&block)
      @errors.each_pair do |key, value|
        block.call(key, value)
      end
    end
    
  end
  
end