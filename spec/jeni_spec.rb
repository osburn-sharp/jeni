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
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

source_dir = File.expand_path(File.dirname(__FILE__) + '/../test/examples/source')
target_dir = File.expand_path(File.dirname(__FILE__) + '/../test/examples/target')
FileUtils.rm_f Dir.glob("#{target_dir}/**")

describe Jeni do

  it "should create a file" do
    source_file = 'jeni.rb'
    target_file = File.join(target_dir, source_file)
    Jeni::Installer.new(source_dir, 'test') do |jeni|
      jeni.quiet(true)
      jeni.file(source_file, target_file)
    end.run!
    FileTest.exists?(target_file).should be_true
  end
  
  it "should create a directory" do
    target_file = File.join(target_dir, 'archive')
    Jeni::Installer.new(source_dir, 'test') do |jeni|
      jeni.quiet(true)
      jeni.directory(source_dir, target_file)
    end.run!
    #FileTest.exists?(target_file).should be_true
  end
  
  it "should create an empty directory" do
    empty_dir = File.join(target_dir, 'cache')
    Jeni::Installer.new(source_dir, 'test') do |jeni|
      jeni.quiet(true)
      jeni.empty_directory(empty_dir)
    end.run!
    FileTest.directory?(empty_dir). should be_true
  end
  
  it "should check if a file exists" do
    exec = File.join(source_dir, '..', 'test1.rb')
    res = Jeni::Installer.new(source_dir, 'test') do |jeni|
      jeni.quiet(true)
      jeni.file_exists?(exec)
    end.run!
    res.should be_true
  end
  
  it "should check if an executable exists" do
    exec = File.join(source_dir, '..', 'test1.rb')
    res = Jeni::Installer.new(source_dir, 'test') do |jeni|
      jeni.quiet(true)
      jeni.file_exists?(exec, :executable=>true)
    end.run!
    res.should be_true
  end
  
  it "should fail if a file is not executable" do
    exec = File.join(source_dir, 'jeni.rb')
    res = Jeni::Installer.new(source_dir, 'test') do |jeni|
      jeni.quiet(true)
      jeni.file_exists?(exec, :executable=>true)
    end.run!
    res.should_not be_true
  end
  
  it "should create a link" do
    target_file = File.join(target_dir, 'jeni_link.rb')
    Jeni::Installer.new(source_dir, 'test') do |jeni|
      jeni.quiet(true)
      jeni.link('jeni.rb', target_file)
    end.run!
    FileTest.symlink?(target_file).should be_true
  end

end
