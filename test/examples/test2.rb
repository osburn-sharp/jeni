#!/usr/bin/env ruby18
# simple etst of Jeeni
require 'rubygems'
$LOAD_PATH.unshift File.expand_path('../../lib', File.dirname(__FILE__))
require 'jeni'

test_dir = File.dirname(__FILE__)
target_dir = File.join(test_dir, 'target2')
FileUtils.mkdir(target_dir) unless FileTest.directory?(target_dir)
FileUtils.rm_f Dir.glob("#{target_dir}/**")

pretend = true

Jeni::Installer.new(test_dir, 'jeni') do |jeni|
  jeni.pretend(false)
  jeni.verbose(false)
  jeni.file('source/jeni.rb', File.join(target_dir, 'jeni_test.rb'), :chown=>'robert')
  jeni.file('source/jeni.rb', File.join(target_dir, 'jeni.rb'), :chown=>'robert')
  jeni.file('source/shebang.rb', File.join(target_dir, 'shebang.rb'), :chown=>'robert', :chmod=>0755)
  jeni.directory('source', target_dir)
  jeni.template('source/template.haml.rb', File.join(target_dir, 'jeni_template.rb'), :greeting=>'Welcome and well met', :author=>'Me')
  jeni.template('source/coati.haml.conf', File.join(target_dir, 'coati.conf'), :root=>'/home/robert/dev/rails/coati', :app_name=>'coati')
  jeni.standard_template('template.haml.rb', File.join(target_dir, 'std_template.rb'), :greeting=>'How do you do?', :author=>'Robert')
  jeni.link('source/jeni.rb', File.join(target_dir, 'jeni_link.rb'))
  jeni.link('source/shebang.rb', File.join(target_dir, 'jeni_link.rb'))
  jeni.link('source/jeni.rb', File.join(target_dir, 'jeni.rb'))
end.run!