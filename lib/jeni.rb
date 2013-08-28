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

require 'rubygems'
require 'jeni/utils'
require 'jeni/actions'
require 'jeni/io'
require 'jeni/options'
require 'jeni/errors'
require 'jeni/optparse'

require 'etc'

# = Jeni
#
# A simple installer designed to support gems by installing the things
# that gem cannot install. For example: sbin files, /etc files.
#
# To use Jeni, you need to create an instance in a block, use the various methods
# to copy files etc, and run the resulting block:
#
#   Jeni::Installer.construct('my_gem) do |jeni|
#     jeni.pretend
#     jeni.file('source.rb', '/usr/sbin/target')
#     jeni.file('etc/config.rb', '/etc/my_gem.rb', :chown=>'root')
#   end.run!
#
module Jeni
  
  # The main class to be used by callers to construct an installation script. 
  # See {file:README.md Readme} for full details.
  #
  # Included modules are:
  #
  # * Options - methods to allow the direct assignment of defaults etc
  # * Optparse - process command line options using Optparse
  # * Utils, Actions and IO - methods under the bonnet
  class Installer
    
    include Jeni::Utils
    include Jeni::Actions
    include Jeni::IO
    include Jeni::Options
    include Jeni::Optparse
    
    extend Jeni::IO # get say for the class as well!
    
    # create a jeni installer instance
    #
    # @param [String] source_root is the path to the source to copy from etc
    # @param [String] app_name is the name of the app being installed
    # @yield [self] returns self
    def initialize(source_root, app_name) 
      @app_name = app_name
      #@gem_spec = Gem::Specification.find_by_name(@gem_name)
      #@gem_dir = @gem_spec.gem_dir
      @source_root = source_root
      @target_root = '/usr/local/'
      @commands = []
      @errors = {}
      @owner = nil
      @gem_dir = nil
      # record any new users and groups requested
      @new_users = Array.new
      @new_groups = Array.new
      if block_given? then
        yield self
      else
        return self
      end
    end
    
    # @private
    def set_gem(dir)
      @gem_dir = dir
      @gem = true
    end
    
    # allow scripters to know where the gem directory is
    attr_reader :gem_dir
    
    # allow the caller to know where relative targets will be installed
    attr_reader :target_root
    
    #protected :set_gem
    
    
    # construct an installer to install files etc after a gem install.
    #
    # @param [String] gem_name is the name of the gem to install from
    # @yield [Jeni::Installer] an instance through which options and actions can
    #   be taken
    #
    def self.new_from_gem(gem_name)
      gem_spec = Gem::Specification.find_by_name(gem_name)
      installer = self.new(gem_spec.gem_dir, gem_name)
      installer.set_gem(gem_spec.gem_dir)
      if block_given? then
        yield(installer)
      end
      return installer
    rescue Gem::LoadError
      say(:fatal, "Gem name #{gem_name} could not be found", :error)
      return nil
    end
    
    # action the commands, or not, depending on the options selected
    def run!
      if self.errors? then
        unless @quiet
          puts "There are errors in the installation, which has been cancelled:"
          puts ""
        end

        self.each_error do |error, target|

          say(error, target, :error)
        end
        return false
      end
      # no errors, so do something
      @commands.each do |command|
        verb = command.keys.first
        args = command[verb]
        case verb
        when :mkdir
          mkdir(args)
        when :file
          copy(args[0], args[1])
        when :chown
          chown(args[:file], args[:owner])
        when :chgrp
          chgrp(args[:file], args[:group])
        when :chmod
          chmod(args[:file], args[:mode])
        when :generate
          generate(args[0], args[1], args[2])
        when :wrap
          wrap(args[0], args[1], args[2])
        when :link
          link_it(args[0], args[1])
        when :user
          add_user(args[:name], args[:options])
        when :group
          add_group(args[:name], args[:options])
        when :say
          say(args[0], args[1], args[2])
        end
      end
      
      return true
      
    rescue JeniError => err
      puts "An error has occurred. Aborting."
      puts err.inspect
      err.each do |el|
        puts el
      end
    end
    
    # check that a given file exists and report an error otherwise
    #
    # @param [String] path to the file that must exist
    #
    def exists?(path)
      check_file(path)
    end
    
    # copy a file from the source, relative to the gem home to the target
    # 
    # If the target is relative it will joined to the target_root, which is
    # by default /usr/local. This root can be changed to /usr with either
    # {Jeni::Options.usr} or through {Jeni::Optparse}.
    # 
    # @param [String] source is the gem-relative path to the file to copy
    # @param [String] target is a relative or absolute path to copy to
    # @params [Hash] opts options for copying the file
    # @option opts [String] :chown the name of the owner
    # @option opts [String] :chgrp the name of the group
    # @option opts [Octal] :chmod octal bit settings for chmod
    # 
    # Note :chown and :chgrp override the global options e.g. {Jeni::Options#owner owner}
    def file(source, target, opts={})
      #gsource = File.join(@source_root, source)
      #target_dir = File.dirname(target)
      owner = opts[:chown] || @owner
      chmod = opts[:chmod]
      
      gsource = check_file(source)
      gtarget = check_target(target, owner)
      check_chmod(chmod)
      
      @commands << {:file => [gsource, gtarget]}
      process_options(opts, gtarget)
    end
    
    # copy all of the files in the source directory to the target directory
    #
    # @param (see #file)
    # @option (see #file)
    #
    def directory(source, target, opts={})
      #gsource = File.join(@source_root, source)
      gsource = check_file(source)
      Dir["#{gsource}/*"].each do |sourcefile|
        src_path = sourcefile.sub(@source_root + '/', '')
        tgt_path = sourcefile.sub(gsource + '/', '')
        targetfile = File.join(target, tgt_path)
        if FileTest.directory?(sourcefile) then
          self.directory(sourcefile, targetfile)
        else
          self.file(sourcefile, targetfile, opts)
        end

      end
    end
    
    # create an empty directory and change the owner if specified. This ignores
    # any nomkdir setting. Do not use this method together with directory as
    # jeni will get confused about whether the directory exists or not!
    #
    # @param [String] target is the absolute path of the empty directory to create
    # @param [Hash] opts to customise the directory
    # @option (see #file)
    #
    def empty_directory(target, opts={})
      @commands << {:mkdir => target}
      owner = opts[:chown] || @owner
      chmod = opts[:chmod]
      process_options(opts, target)
    end
    
    # check that a file exists
    #
    # @param [String] file to test, relative to the source (e.g. gem)
    # @param [Hash] options
    # @option opts [Symbol] :executable to check if it is also executable
    #
    def file_exists?(file, opts={})
      check_file(file)
      check_executable(file) if opts.has_key?(:executable)
      @commands << {:say => [:exists, file, :ok]}
    end
    
    # create a new user
    #
    # @param [String] name of the new user to create
    # @param [Hash] options for creating the user
    # @option opts [Integer] :uid user id instead of next available
    # @option opts [Integer] :gid group id instead of next available
    # @option opts [String] :home path to home directory for user, defaults to /home/$user
    # @option opts [String] :shell path to shell for user, defaults to /bin/bash
    # @option opts [Boolean] :skip set true to skip if user exists else fail
    # @option opts [Boolean] :user_group to create a user group for this user
    #
    def user(name, opts={})
      skip = opts[:skip]
      skip = check_new_user(name, opts, skip)
      check_root(skip)
      opts[:skip] =  skip
      @commands << {:user => {:name => name, :options => opts}}
    end
    
    # create a new group
    #
    # @param [String] name of the new group to create
    # @param [Hash] options for creating the user
    # @option opts [Integer] :gid group id instead of next available
    # @option opts [Boolean] :skip set true to skip if user exists else fail
    #
    def group(name, opts={})
      skip = opts[:skip]
      skip = check_new_group(name, opts, skip)
      check_root(skip)
      opts[:skip] =  skip
      @commands << {:group => {:name => name, :options => opts}}
    end
    
    # generate a file from a template using the Haml engine for plain text input.
    # The template is prefixed with the ':plain' directive. Variables can be
    # passed to the template using the locals hash (see below). See {file: README.md Readme}
    # for more details.
    #
    # the file can be used for anything, with ruby code inserting as #\{code\}. 
    #
    # @param [String] source is the path to the template to render
    # @param [String] target is an absolute path to the generated file
    # @param [Hash] locals is an optional hash that will be converted to local params within the template
    # 
    # include :chown=>'user' in the locals to change the owner as well. It will be stripped from the locals
    # passed to the template. Similarly for :chmod and :chgrp.
    # 
    def template(source, target, locals={})
      #gsource = File.join(@source_root, source)
      #target_dir = File.dirname(target)
      opts = Hash.new
      opts[:chown] = locals.delete(:chown)
      opts[:chmod] = locals.delete(:chmod)
      opts[:chgrp] = locals.delete(:chgrp)
      
      gsource = check_file(source)
      gtarget = check_target(target, opts[:owner])
      check_chmod(opts[:chmod])
      
      @commands << {:generate => [gsource, gtarget, locals]}
      process_options(opts, gtarget)
    end
    
    # as for {Jeni::Installer#template} but searches for the source template from a list of predefined
    # directories. These are ~/.jermine/templates and /usr/local/share/templates
    # 
    # @param (see #template)
    #
    def standard_template(source, target, locals={})
      # search for the template until it is found
      gsource = get_template(source)
      opts = Hash.new
      opts[:chown] = locals.delete(:chown)
      opts[:chmod] = locals.delete(:chmod)
      opts[:chgrp] = locals.delete(:chgrp)
      
      gtarget = check_target(target, opts[:owner])
      check_chmod(opts[:chmod])
      
      @commands << {:generate => [gsource, gtarget, locals]}
      process_options(opts, gtarget)
    end
    
    # create a wrapper script at target to call source in a similar manner to Gem's wrapper
    # 
    # The wrapper follows the same rules as for a gem, so its shebang can be set by the original
    # file being wrapped, or by :custom_shebang in your .gemrc
    #
    # @param [String] source is the relative path to the file to wrap
    # @param [String] target is an absolute path for the wrapper
    # @params [Hash] opts options for wrapping the file
    # @option opts [String] :chown the name of the owner
    #
    def wrapper(source, target, opts={})
      #gsource = File.join(@source_root, source)
      owner = opts[:chown] || @owner
      
      check_gem(:wrapper)
      gsource = check_file(source)
      gtarget = check_target(target, owner)
      
      @commands << {:wrap => [source, gtarget, gsource]}
      @commands << {:chmod => {:file => gtarget, :mode => 0755}} if opts.has_key?(:chmod)
    end
    
    # create a link at target to source
    #
    # @param [String] source is the gem-relative path to the file to link
    # @param [String] target is an absolute path for the link
    #
    def link(source, target)
      #gsource = File.expand_path(File.join(@source_root, source))
      gsource = check_file(source)
      gtarget = check_target(target)
      @commands << {:link => [gsource, gtarget]}
    end
    
    # output a message in the same format as other messages
    #
    # @param [String] action a single word describing the action taking place
    # @param [String] message a short message concerning the action
    # @param [Symbol] status can be :ok, :no_change, :warning or :error
    #
    def message(action, message, status)
      @commands << {:say => [action, message, status]}
    end

    
  end
end