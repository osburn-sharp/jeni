# JENI

_(a.k.a Jumpin Ermin's Nifty Installer)_

A simple alternative to rubigen and thor that can be used to create a post-install script 
for a gem needing more than the standard file ops covered by rubygems. It can also be used 
for straight directories instead of gems, if required.

**GitHub:** [https://github.com/osburn-sharp/jeni](https://github.com/osburn-sharp/jeni)

**RubyDoc:** [http://rdoc.info/github/osburn-sharp/jeni/frames](http://rdoc.info/github/osburn-sharp/jeni/frames)

**RubyGems:** [https://rubygems.org/gems/jeni](https://rubygems.org/gems/jeni)

## Usage

To install, 

    gem install jeni.
    
It is a plain library with no binaries or the like. Documentation is available from [RDoc]()

## Getting Started

To use, create an executable, require jeni, create an instance of `Jeni::Installer`
using the new or new_from_gem method and a block, call whatever methods you need to install files
etc. and then `run!` the block to do the real work. See documentation for details of available methods
and options.

### Example

This is a simple example:

    # start the installation block
    Jeni::Installer.new_from_gem('my_gem') do |jeni|
      jeni.pretend(opt[:pretend]) 
      # copy a file
      jeni.file('source.rb', '/etc/target.rb')
      # create a wrapper
      jeni.wrapper('sbin/jenerate.rb', '/usr/sbin/jenerate')
    end.run!
    # and run jeni

### Actions

Jeni has the following actions, which for a gem (new_from_gem) will look for the source relative to the gem,
and for a directory (new) will look relative to that directory:

+ *{Jeni::Installer#file file}* -
  copy a file from the source to the filesystem
  
+ *{Jeni::Installer#directory directory}* - 
  copy all the files in a directory to the filesystem
  
+ *{Jeni::Installer#empty_directory empty_directory}* -
  create an empty directory with no contents.
  
+ *{Jeni::Installer#template template}* -
  generate a file from a template
  
+ *{Jeni::Installer#standard_template standard_template}* -
  as for template, but looks in standard locations for the template file
  
+ *{Jeni::Installer#wrapper wrapper}* - 
  create a wrapper script that calls a gem binary/script - limited to gems only
  
+ *{Jeni::Installer#link link}* -
  create a link to a file
  
+ *{Jeni::Installer#message message}* -
  output a message to the user
  
+ *{Jeni::Installer#user user}* -
  add a new user to the system
  
+ *{Jeni::Installer#group group}* -
  add a new group to the system
  
+ *{Jeni::Installer#file_exists? file_exists?}* -
  check that a given file exists, and optionally that it is executable
  
The file, directory and template methods take an options hash, which accepts the following options:

+ *:chown* - change the owner of the copied file(s)
+ *:chgrp* - change the group of the copied file(s)
+ *:chmod* - change the mode of the copied file(s) which should be given in octal (e.g. 0755 and not 755 or '755')

For example:

    jeni.file('source.rb', '/etc/target.rb', :chown=>'robert')
    
If the source is a relative path then it will be looked for relative to the Installer.
So, for a gem {Jeni::Installer.new_from_gem} it will be relative to the gem's directory and for a directory 
{Jeni::Installer.new} it will be relative to that. If the source is an absolute path (starts with '/')
then it will be used as given.
    
Global options can also be set, as defined in #{Jeni::Options}. The same options can be set using {Jeni::Optparse#optparse} 
to automatically process command line options. Call it with ARGV instead of manually setting Jeni's options.

    Jeni::Installer.new_from_gem('jeni') do |jeni|
      jeni.optparse(ARGV)
      jeni.file('source/jeni.rb', File.join(target_dir, 'jeni_test.rb'), :chown=>'robert')
      jeni.file('source/jeni.rb', File.join(target_dir, 'jeni.rb'), :chown=>'robert')
      jeni.directory('source', target_dir)
      jeni.wrapper('source/executable', File.join(target_dir, 'executable'), :chmod=>true)
      jeni.link('source/jeni.rb', File.join(target_dir, 'jeni_link.rb'))
    end.run!


## Code Walkthrough

The main class is {Jeni::Installer} and the instance methods provide the actions that the installer can carry out. 
Each method makes relevant checks (e.g. target directory is writeable) and queues one of more action requests, 
e.g. to copy a file and then change the owner. The {Jeni::Installer#run!} method checks if any errors were
raised by the checks and aborts with error messages if they were. Otherwise it dispatches each action method with the
saved parameters. 

The hard work is all done in {Jeni::Actions} and these methods are not intended to be directly accessible to the user.
Each action method controls messages and any interaction with the user and then carries out the intended action if
required. User IO is achieved through {Jeni::IO}. If interaction is required the user is prompted with a list of choices
and the appropriate action carried out as a result. This could include, for example, printing a diff listing between
an existing file and a new file intended to replace it.

Jeni has a variety of options that can be set and are separately defined in {Jeni::Options}. Alternatively, use 
{Jeni::Optparse#optparse} mixin to set up these options from the command line (recommended).

The code is available from [GitHub](https://github.com/osburn-sharp/jeni)

## Dependencies

A ruby compiler - works with 1.8.7.

Check the {file:Gemfile} for other dependencies.

### Documentation

Documentation is best viewed using Yard. Documentation is available from [Rubydoc](http://rdoc.info/github/osburn-sharp/jeni/frames)

## Testing/Modifying

Testing can be carried out with the GitHub sources and uses rspec. There is a complete rspec test suite 
for the Utils module (spec/jeni_utils_spec.rb). 

There is also a manual test that is an example that shows a range of possible results for a mock gem. Run this with

    $ test/examples/test1.rb
    
The same tests are used for a source directory instead of a gem:
  
    $ test/examples/test2.rb
    
There is also a variant on the above that uses optparse and can therefore accept any of the proposed
options:

    $ test/examples/test_args -p
    
Will pretend. For more details:

    $ test/examples/test_args --help
    
To test users and groups there is the following, which will fail if not run as root:

    $ test/examples/test_users
    
## Bugs

Details of any unresolved bugs and change requests are in {file:Bugs.rdoc Bugs}. Issues can be logged and tracked through
[GitHub](https://github.com/osburn-sharp/jeni/issues).

## Changelog

See {file:History.txt} for a summary change history.

## Author and Contact

The author may be contacted by via [GitHub](http://github.com/osburn-sharp)

## Copyright and Licence

Copyright (c) 2012 Robert Sharp

This software is licensed under the terms defined in {file:LICENCE.rdoc}

## Warranty

This software is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.