#!/usr/bin/env ruby18
# simple etst of Jeeni
require 'rubygems'
$LOAD_PATH.unshift File.expand_path('../../lib', File.dirname(__FILE__))
require 'jeni'
require 'rspec/mocks/standalone'

gspec = double("Gem::Specification")
Gem::Specification.stub(:find_by_name).and_return(gspec)
test_dir = File.expand_path(File.dirname(__FILE__))
target_dir = File.join(test_dir, 'target2')
FileUtils.mkdir(target_dir) unless FileTest.directory?(target_dir)
FileUtils.rm_f Dir.glob("#{target_dir}/**")
gspec.should_receive(:gem_dir).and_return(test_dir)
pretend = true

Jeni::Installer.new_from_gem('jeni') do |jeni|
  jeni.pretend(false)
  jeni.verbose(false)
  jeni.file('source/jeni.rb', File.join(target_dir, 'jeni_test.rb'), :chown=>'robert')
  jeni.file('source/jeni.rb', File.join(target_dir, 'jeni.rb'), :chown=>'robert')
  jeni.file('source/shebang.rb', File.join(target_dir, 'shebang.rb'), :chown=>'robert', :chmod=>0755)
  jeni.directory('source', target_dir)
  jeni.message('invoke', 'templating', :white)
  jeni.template('source/template.haml.rb', File.join(target_dir, 'jeni_template'), :chown=>'robert', :greeting=>'Welcome and well met', :author=>'Me')
  jeni.wrapper('source/executable', File.join(target_dir, 'executable'), :chmod=>true)
  jeni.link('source/jeni.rb', File.join(target_dir, 'jeni_link.rb'))
  jeni.link('source/shebang.rb', File.join(target_dir, 'jeni_link.rb'))
  jeni.link('/etc/init.d/unicorn', File.join(target_dir, 'unicorn.jeni'))
end.run!