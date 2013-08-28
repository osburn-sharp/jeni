#
#
# = Title
#
# == SubTitle
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
  
  # Implementation mixin containing methods for each action that Jeni carries out
  module Actions
    
    # Create a copy of the source file as the target file
    #
    # the checks are really redundant, but have been left in as belt and braces
    #
    def copy(source, target)
      # check the source exists
      puts "Copying #{source} to #{target}" if @verbose
      unless FileTest.exists?(source)
        say(:missing, source, :error)
        return nil
      end
      #check the target directory is writable
      target_dir = File.dirname(target)
      unless FileTest.writable?(target_dir)
        say(:unwritable, target_dir, :error)
        return nil
      end
      # check if the target exists
      if FileTest.exists?(target) then
        
        unless FileUtils.compare_file(source, target) then
          say(:exists, target, :warning)
          loop do
            case ask('Do you want to overwrite', :no)
            when :yes
              say(:overwrite, target, :ok)
              break
            when :no, :skip
              say(:skipping, target, :warning)
              return nil
            when :diff
              puts Diffy::Diff.new(target, source, :source=>'files').to_s(:color)
            when :list
              File.open(target) do |tfile|
                tfile.readline do |line|
                  puts line
                end
              end
            end # case
          end # loop
        else # unless
          # files are the same
          say(:identical, target, :no_change)
          return target
        end # unless
      else # if
        say(:create, target, :ok)
      end
      
      FileUtils.cp(source, target) unless @pretend
      return target
      
    end
    
    # make the given directory, and any intermediates
    def mkdir(target)
      if FileTest.directory?(target)
        say(:identical, target, :no_change)
      elsif @pretend then
        say(:mkdir, target, :ok)
      else
        FileUtils.mkdir_p(target)
        if FileTest.directory?(target) then
          say(:mkdir, target, :ok)
        else
          say(:mkdir, "Failed to make #{target}", :error)
          continue?
        end
      end
    end
    
    # change the owner of a file
    def chown(file, owner)
      message = "#{file} to #{owner}"
      return if @pretend 
      if FileTest.exists?(file) then
        FileUtils.chown(owner, nil, file)
        say(:chown, message, :ok)
      else
        say(:missing, file, :error)
      end
    end
    
    # change the group of a file
    def chgrp(file, owner)
      message = "#{file} to #{owner}"
      return if @pretend 
      if FileTest.exists?(file) then
        FileUtils.chown(nil, owner, file)
        say(:chgrp, message, :ok)
      else
        say(:missing, file, :error)
      end
    end
    
    # make a file executable
    def chmod(file, mode)
      message = "#{file} to #{mode.to_s(8)}"
      return if @pretend 
      if FileTest.exists?(file) then
        FileUtils.chmod(mode,file)
        say(:chmod, message, :ok)
      else
        say(:missing, file, :error)
      end
    end
    
    # generate a file from a template, which is done even if the user
    # request pretend. This ensures that a proper comparison is made
    # with any existing file
    def generate(template_file, target_file, locals={})
      template = [":plain\n"]
      # read in the file, prepending 2 spaces to each line
      File.open(template_file) do |tfile|
        tfile.each_line do |tline|
          template << "  " + tline
        end
      end
      # now create the template as an engine and render it
      engine = Haml::Engine.new(template.join)
      target = engine.render(binding, locals)
      
      puts target if @verbose
      
      # and write it out to the target, but make it a temp
      temp_file = File.join('/tmp', File.basename(target_file) + "._temp")
      File.open(temp_file, 'w') do |tfile|
        target.each_line do |tline|
          tfile.puts tline
        end
      end
      
      # and now copy the temp file to the target
      copy(temp_file, target_file)
      
      # and finally clean up
      FileUtils.rm_f(temp_file)
    end
    
    # return the path to the standard template, which can be found in 
    # the places search below.
    def get_template(source)
      gsource = File.expand_path(File.join('.jermine', 'templates', source), '~')
      unless File.exists?(gsource)
        gsource = File.join('usr', 'local', 'share', 'templates', source)
        unless File.exists(gsource)
          @errors[:missing] = 'Standard template file: #{source}'
          return nil
        end
      end
      return gsource
    end
    
    # create a wrapper for a file, which is specific to a gem
    def wrap(source, target, fullsource)
      #create the wrapper somewhere
      basename = File.basename(source)
      tempname = File.join('/tmp', File.basename(source) + ".wrapper")
      File.open(tempname, 'w') {|f| f.write wrap_file(source, fullsource)}
      copy(tempname, target)
    end
    
    # create a link to a file
    def link_it(source, target)
      if FileTest.exists?(source) then
        if FileTest.symlink?(target) then
          # already got a link, is it identical
          existing_link = File.readlink(target)
          if existing_link == source then
            say(:identical, target, :no_change)
          else
            say(:exists, "#{target} -> #{existing_link}", :warning)
            loop do
              case ask('Do you want to overwrite', :no, 'ynsl')
              when :yes
                say(:overwrite, target, :ok)
                break
              when :no, :skip
                say(:skipping, target, :warning)
                return nil
              else
                puts "Link name: #{target}"
                puts "New target: #{target}"
                puts "Existing target: #{existing_link}"
              end # case
            end # loop
            FileUtils.ln_sf(source, target) unless @pretend
            say(:link, target, :ok)
          end # if
        elsif FileTest.exists?(target)
          say(:exists, "as file: #{target}", :warning)
          loop do
            case ask('Do you want to replace it', :no, 'yns')
            when :yes
              say(:replace, target, :ok)
              break
            when :no, :skip
              say(:skipping, target, :warning)
              return nil
            else
              puts "Please make a valid selection"
            end # case
          end # loop
          FileUtils.rm_f(target) unless @pretend
          FileUtils.ln_s(source, target) unless @pretend
          say(:link, target, :ok)
        else
          FileUtils.ln_s(source, target) unless @pretend
          say(:link, target, :ok)
        end
      else
        say(:missing, source, :error)
      end
    end
    
    
    # create a wrapper script as text
    def wrap_file(source, fullsource)
      
      return <<-TEXT
#{shebang fullsource}
#
# This file was generated by RubyGems.
#
# The application '#{@app_name}' is installed as part of a gem, and
# this file is here to facilitate running it.
#
# Updated to wrap non-bin executables
#

require 'rubygems'

version = "#{Gem::Requirement.default}"

# check if there is a version spec here, e.g.: gem_name _0.1.2_ args
if ARGV.first
  str = ARGV.first
  str = str.dup.force_encoding("BINARY") if str.respond_to? :force_encoding
  if str =~ /\\A_(.*)_\\z/
    # there is, so get it
    version = $1
    ARGV.shift
  end
end

gem_spec = Gem::Specification.find_by_name('#{@app_name}', version)
gem_path = File.join(gem_spec.gem_dir, '#{source}')

gem '#{@app_name}', version
load gem_path
TEXT
      
    end
    
    ##
    # Generates a #! line for +bin_file_name+'s wrapper copying arguments if
    # necessary.
    #
    # If the :custom_shebang config is set, then it is used as a template
    # for how to create the shebang used for to run a gem's executables.
    #
    # The template supports 4 expansions:
    #
    # $env the path to the unix env utility
    # $ruby the path to the currently running ruby interpreter
    # $exec the path to the gem's executable
    # $name the name of the gem the executable is for
    #
    def shebang(source)
      
      env_paths = %w[/usr/bin/env /bin/env]
      
      ruby_name = Gem::ConfigMap[:ruby_install_name] #if @env_shebang
      
      first_line = File.open(source, "rb") {|file| file.gets}
      env_path = nil
  
      if /\A#!/ =~ first_line then
        # Preserve extra words on shebang line, like "-w". Thanks RPA.
        shebang = first_line.sub(/\A\#!.*?ruby\S*((\s+\S+)+)/, "#!#{Gem.ruby}")
        opts = $1
        shebang.strip! # Avoid nasty ^M issues.
      end
  
      if which = Gem.configuration[:custom_shebang]
        which = which.gsub(/\$(\w+)/) do
          case $1
          when "env"
            env_path ||= env_paths.find do |e_path|
                            File.executable? e_path
                          end
          when "ruby"
            "#{Gem.ruby}#{opts}"
          when "exec"
            bin_file_name
          when "name"
            spec.name
          end
        end
  
        return "#!#{which}"
      end
  
      if not ruby_name then
        "#!#{Gem.ruby}#{opts}"
      elsif opts then
        "#!/bin/sh\n'exec' #{ruby_name.dump} '-x' \"$0\" \"$@\"\n#{shebang}"
      else
        # Create a plain shebang line.
        env_path ||= env_paths.find {|e_path| File.executable? e_path }
        "#!#{env_path} #{ruby_name}"
      end
    end
    
    # create a new user
    def add_user(username, opts={})
      if opts[:skip] then
        say(:user, "#{username} already exists", :warning)
        return false
      end
      
      home = opts[:home] || "/home/#{username}"
      shell = opts[:shell] || "/bin/bash"
      uid = opts[:uid]
      gid = opts[:gid]
      user_group = opts[:user_group]
      cmd = "/usr/sbin/useradd -d #{home} -s #{shell}"
      
      cmd << " -u #{uid}" if uid
      cmd << " -g #{gid}" if gid
      cmd << " -U" if user_group
      cmd << " #{username}"
      
      unless @pretend
        system(cmd)
        raise JeniError if $? != 0
      end
      say(:user, "Added user #{username}", :ok)
      
    rescue JeniError
      say(:user, "Failed to add user #{username} with error #{$?}", :error)

    end
    
    # create a new group
    def add_group(group, opts={})
      if opts[:skip] then
        say(:group, "#{group} already exists", :warning)
        return false
      end
      
      gid = opts[:gid]
      cmd = "/usr/sbin/groupadd "
      
      cmd << "-g #{gid}" if gid
      cmd << " #{group}"
      
      unless @pretend
        system(cmd)
        raise JeniError if $? != 0
      end
      say(:group, "Added group #{group}", :ok)
      
    rescue JeniError
      say(:group, "Failed to add user #{username} with error #{$?}", :error)

    end
    
  end
end