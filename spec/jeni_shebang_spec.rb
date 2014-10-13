#
# Author:: Robert Sharp
# Copyright:: Copyright (c) 2014 Robert Sharp
# License:: Open Software Licence v3.0
#
# This software is licensed for use under the Open Software Licence v. 3.0
# The terms of this licence can be found at http://www.opensource.org/licenses/osl-3.0.php
# and in the file copyright.txt. Under the terms of this licence, all derivative works
# must themselves be licensed under the Open Software Licence v. 3.0
# 
#


require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'jeni/errors'
require 'jeni/actions'

proot = File.dirname(File.dirname(__FILE__))
conf_file = File.expand_path(File.dirname(__FILE__) + '/../test/shebang.rb')

# mimic the class without actually having to set one up!
# have to create the odd instance variable along the way.
include Jeni::Actions

describe Jeni do

  
  it "should output a plain specific ruby with and without env" do
    #@gem_spec = Gem::Specification.find_by_name('jerbil')
    Gem.configuration[:custom_shebang] = nil
    expect(shebang(conf_file)).to match(/\A#!\/usr\/bin\/ruby[0-9]{2,2}\z/)
    @env_shebang = true
    expect(shebang(File.join(proot, 'test', 'noshebang.rb'))).to match(/\A#!\/usr\/bin\/env ruby[0-9]{2,2}\z/)
  end
  
  it "should output a custom shebang" do
    Gem.configuration[:custom_shebang] = "$env ruby"
    expect(shebang(conf_file)).to match(/\A#!\/usr\/bin\/env ruby\z/)
  end
  
  it "should output a custom shebang with all variables defined" do
    @app_name = 'jerbil'
    Gem.configuration[:custom_shebang] = "$env $ruby $exec $name"
    expect(shebang(conf_file)).to match(/\A#!\/usr\/bin\/env \/usr\/bin\/ruby[0-9]{2,2} shebang.rb jerbil\z/)
  end
  
  it "should output a shebang with options" do
    @env_shebang = false
    expect(shebang(File.join(proot, 'test', 'optshebang.rb'))).to match(/\A#!\/usr\/bin\/env ruby[0-9]{2,2} \-x\z/)
  end

end
