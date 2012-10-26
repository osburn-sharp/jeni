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
# Tests out the Jeni::Utils module as a mixin for Jeni
# 
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'jeni/utils'
require 'jeni/options'
require 'jeni/errors'
require 'jeni/io'
require 'colored'

test_dir = File.expand_path(File.dirname(__FILE__) + '/../test/examples')

class JeniUtils
  include Jeni::Utils
  include Jeni::Options
  include Jeni::IO
  include Jeni::Actions
  def initialize
    @app_name = 'jeni'
    @errors = {}
    @commands = []
    @source_root = File.expand_path(File.dirname(__FILE__) + '/../test/examples')
  end
  attr_accessor :errors
end

describe Jeni do

  before(:each) do
    @jeni = JeniUtils.new
  end

  it "should print a message to stdout" do
    @jeni.should_receive(:puts)
    @jeni.say(:create, "/a/file")
  end
  it "should print a message of any type to stdout" do
    @jeni.should_receive(:puts)
    @jeni.say(:unknown, "/a/file")
  end
  
  it "should ask a question and get a default response" do
    @jeni.should_receive(:print)
    @jeni.ask('Do you want to do this').should == :no
  end
  
  it "should check a relatively file and provide an absolute path" do
    @jeni.check_file('test1.rb').should == File.join(test_dir, 'test1.rb')
  end
  
  it "should check and return an absolute path" do
    @jeni.check_file('/etc/hosts').should == '/etc/hosts'
  end
  
  it "should reject a non-existent source" do
    nofile = '/a/nonexistent/file.rb'
    response = @jeni.say(:missing, nofile, :error, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.copy(nofile, '/who/cares').should be_nil
  end
  
  it "should reject an unwritable target directory" do
    udir = '/who/cares'
    response = @jeni.say(:unwritable, udir, :error, true)
    @jeni.should_receive(:puts).with(response)
    FileUtils.touch("/tmp/jeni_utils.rb")
    @jeni.copy("/tmp/jeni_utils.rb", "/who/cares/anyway.rb").should be_nil
  end
  
  it "should just create a file that does not exist" do
    source = File.join(test_dir,  'source', 'jeni.rb')
    target = File.join(test_dir,  'target', 'jeni.rb')
    FileUtils.rm(target) if FileTest.exists?(target)
    response = @jeni.say(:create, target, :ok, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.copy(source, target).should == target
    FileTest.exists?(target).should be_true
  end
  
  it "should spot a file that is identical" do
    source = File.join(test_dir,  'source', 'jeni.rb')
    target = File.join(test_dir,  'target', 'jeni.rb')
    response = @jeni.say(:identical, target, :no_change, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.copy(source, target).should == target
    FileTest.exists?(target).should be_true
  end
  
  it "should spot a file that would overwrite and skip it" do
    source_old = File.join(test_dir,  'source', 'jeni.rb')
    source = File.join(test_dir,  'source', 'jeni-diff.rb')
    target = File.join(test_dir,  'target', 'jeni.rb')
    response = @jeni.say(:exists, target, :warning, true)
    response2 = @jeni.say(:skipping, target, :warning, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.should_receive(:puts).with(response2)
    @jeni.should_receive(:print)
    @jeni.copy(source, target).should be_nil
    FileTest.exists?(target).should be_true
    FileUtils.compare_file(source_old, target).should be_true
  end
  
  
  it "should spot a file that would overwrite and diff it" do
    source_old = File.join(test_dir,  'source', 'jeni.rb')
    source = File.join(test_dir,  'source', 'jeni-diff.rb')
    target = File.join(test_dir,  'target', 'jeni.rb')
    diff = Diffy::Diff.new(target, source, :source=>'files').to_s(:color)
    response = @jeni.say(:exists, target, :warning, true)
    response2 = @jeni.say(:skipping, target, :warning, true)
    @jeni.should_receive(:puts).once.with(response)
    @jeni.should_receive(:print).once
    @jeni.should_receive(:gets).and_return('d')
    @jeni.should_receive(:puts).with(diff)
    @jeni.should_receive(:print).once
    @jeni.should_receive(:gets).and_return('n')
    @jeni.should_receive(:puts).once.with(response2)
    #@jeni.should_receive(:print)
    @jeni.copy(source, target).should be_nil
    FileTest.exists?(target).should be_true
    FileUtils.compare_file(source_old, target).should be_true
  end
  
  it "should spot a file that would overwrite and overwrite it" do
    source = File.join(test_dir,  'source', 'jeni-diff.rb')
    target = File.join(test_dir,  'target', 'jeni.rb')
    response = @jeni.say(:exists, target, :warning, true)
    response2 = @jeni.say(:overwrite, target, :ok, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.should_receive(:puts).with(response2)
    @jeni.should_receive(:print)
    @jeni.should_receive(:gets).and_return('y')
    @jeni.copy(source, target).should == target
    FileTest.exists?(target).should be_true
    FileUtils.compare_file(source, target).should be_true
  end
  
  it "should create a file from a template" do
    temp = File.join(test_dir, 'source', 'template.haml.rb')
    target = File.join(test_dir,  'target', 'jeni_template.rb')
    FileUtils.rm(target) if FileTest.exists?(target)
    response = @jeni.say(:create, target, :ok, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.generate(temp, target, :greeting=>"Welcome", :author=>"Robert Sharp")
    FileTest.exists?(target).should be_true
  end
  
  it "should create a wrapper" do
    source = 'source/jeni.rb'
    full_source = File.join(test_dir, source)
    wrapper = @jeni.wrap_file(source, full_source)
    copy = File.readlines(File.join(test_dir, 'target', 'test.rb')).join('')
    wrapper.should == copy
  end
  
  it "should create a shebang" do
    sb = @jeni.shebang(File.join(test_dir, 'source/jeni.rb'))  
    sb.should match(/\A#!\/usr\/bin\/env ruby18\z/)
    #sb = @jeni.shebang(test_dir, 'source/shebang.rb')    
    #sb.should match(/\A#!\/usr\/bin\/env ruby18 -w\z/)
  end
  
  it "should check for a file that exists" do
    file = File.join(test_dir, 'source', 'jeni.rb')
    @jeni.check_file(file)
    @jeni.errors.length.should == 0
  end
  
  it "should check for a file that does not exist" do
    file = File.join(test_dir, 'source', 'freddie.rb')
    @jeni.check_file(file)
    @jeni.errors.length.should == 1
    @jeni.each_error do |key, value|
      key.should == :missing
      value.should == file
    end
  end
  
  it "should check that a target directory exists" do
    target = File.join(test_dir, "target", "jeni.rb")
    @jeni.check_target(target)
    @jeni.errors?.should be_false
  end
  
  it "should raise an error if target directory does not exist with nomkdir" do
    target = File.join(test_dir, "target", 'another', "jeni.rb")  
    @jeni.nomkdir
    @jeni.check_target(target)
    @jeni.errors?.should be_true
  end

  it "should mkdir if target directory does not exist" do
    target = File.join(test_dir, "target", 'another', "jeni.rb")  
    @jeni.nomkdir(false)
    @jeni.check_target(target)
    @jeni.errors?.should be_false
  end
  
  it "should check a valid user" do
    valid_user = 'root'
    @jeni.check_user(valid_user)
    @jeni.errors?.should be_false
  end
  
  it "should raise an error for an invalid user" do
    invalid_user = "peppapigsgreataunt"
    @jeni.check_user(invalid_user)
    @jeni.errors?.should be_true
    @jeni.each_error { |k,v| k.should == :no_user; v.should == "User does not exist: #{invalid_user}"} 
  end
  
  it "should change the mode for a file" do
    source = File.join(test_dir, "source", "shebang.rb")
    target = File.join(test_dir, "target", "shebang.rb")
    FileUtils.rm_f(target) if FileTest.exists?(target)
    response = @jeni.say(:create, target, :ok, true)
    response2 = @jeni.say(:chmod, "#{target} to 755", :ok, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.should_receive(:puts).with(response2)
    @jeni.copy(source, target)
    @jeni.chmod(target, 0755)
    FileTest.executable?(target).should be_true
  end
  
  it "should check a new user" do
    @jeni.check_new_user("peppapig", {}, false)
    @jeni.each_error do |err|
      puts err
    end
    @jeni.errors?.should be_false
    @jeni.check_new_user("peppapig", {:uid=>10101}, false)
    @jeni.errors?.should be_false
    @jeni.check_new_user("peppapig", {:uid=>10101, :home=>'/home/peppa', :shell=>'/bin/bourne'}, false)
    @jeni.errors?.should be_false
  end
  
  it "should throw errors for invalid users" do
    @jeni.check_new_user("daemon", {}, false)
    @jeni.errors?.should be_true
    @jeni.errors = {}
    @jeni.check_new_user("peppapig", {:uid=>2}, false)
    @jeni.errors?.should be_true
    @jeni.errors = {}
    @jeni.check_new_user("peppapig", {:gid=>10101}, false)
    @jeni.errors?.should be_true
  end
  
  it "should create a new user" do
    cmd = "/usr/sbin/useradd -d /home/peppapig -s /bin/bash -u 10101 -g 100 peppapig"
    @jeni.should_receive(:system).with(cmd)
    response = @jeni.say(:user, "Added user peppapig", :ok, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.add_user("peppapig", :uid=>10101, :gid=>100)
  end
  
  it "should check a new group" do
    @jeni.check_new_group("piglets", {}, false)
    @jeni.errors?.should be_false
    @jeni.check_new_group("piglets", {:gid=>10101}, false)
    @jeni.errors?.should be_false
  end
  
  it "should throw errors for invalid groups" do
    @jeni.check_new_group("users", {}, false)
    @jeni.errors?.should be_true
    @jeni.errors = {}
    @jeni.check_new_group("piglets", {:gid=>100}, false)
    @jeni.errors?.should be_true
  end

  it "should create a new group" do
    cmd = "/usr/sbin/groupadd -g 10101 piglets"
    @jeni.should_receive(:system).with(cmd)
    response = @jeni.say(:group, "Added group piglets", :ok, true)
    @jeni.should_receive(:puts).with(response)
    @jeni.add_group("piglets", :gid=>10101)
  end
  
end











