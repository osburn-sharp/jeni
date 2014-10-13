# JENI

A simple alternative to rubigen and thor that can be used to create a post-install script 
for a gem needing more than the standard file ops covered by rubygems. It can also be used 
for straight directories instead of gems, if required.

**GitHub:** [https://github.com/osburn-sharp/jeni](https://github.com/osburn-sharp/jeni)

**RubyDoc:** [http://rubydoc.info/github/osburn-sharp/jeni/frames](http://rubydoc.info/github/osburn-sharp/jeni/frames)

**RubyGems:** [https://rubygems.org/gems/jeni](https://rubygems.org/gems/jeni)

## Usage

To install, 

    gem install jeni.
    
It is a plain library with no binaries or the like. To use it, you need to write a ruby
script.

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
      # create a wrapper in /usr/local
      jeni.wrapper('sbin/jenerate.rb', 'sbin/jenerate')
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

If the target is a relative path then it will be relative to /usr/local unless you
use the -u switch (with the optparse option) or the {Jeni::Options.usr} method to set
it to '/usr'.
    
Global options can also be set, as defined in {Jeni::Options}. The same options can be set using {Jeni::Optparse#optparse} 
to automatically process command line options. Call it with ARGV instead of manually setting Jeni's options.

    Jeni::Installer.new_from_gem('jeni') do |jeni|
      jeni.optparse(ARGV)
      jeni.file('source/jeni.rb', File.join(target_dir, 'jeni_test.rb'), :chown=>'robert')
      jeni.file('source/jeni.rb', File.join(target_dir, 'jeni.rb'), :chown=>'robert')
      jeni.directory('source', target_dir)
      jeni.wrapper('source/executable', File.join(target_dir, 'executable'), :chmod=>true)
      jeni.link('source/jeni.rb', File.join(target_dir, 'jeni_link.rb'))
    end.run!

### Templates

Jeni can do more than copy and link files. It can also generate files from a simple
template. The templating engine is [HAML](http://haml.info/) but Jeni processes the
template so that it is treated as plain text (otherwise HAML would try to convert)
the file into HTML). 

The main reason for having a template is to substitute local values into common files.
For example, it can be used to create a config file for a gem that can point to files
within the gem itself - useful for Sinatra with the app directory distributed in the gem.

To set a local variable, simply add it as a hash pair to the template call:

    jeni.template('source/template.haml.rb', 
      File.join(target_dir, 'app.conf'), 
      app_dir:File.join(jeni.gem_dir, 'app'))
    
Note that Jeni provides the gem directory through its own method {Jeni}Within the template, the hash key becomes a variable: 'app_dir' that can be interpolated
in the usual manner:

    # my config file
    APP_ROOT=#{app_dir}    

Finally, in case it might be useful, you can also have templates stored in standard
places (~/.jeni/templates and /usr/local/share/templates) and Jeni will search for them when
you use {Jeni::Installer#standard_template} (you only need to pass the basename).
    
### Wrappers, gems and rubies

Jeni might not be necessary with Gems could install more files. With this in mind, Jeni tries to do
the same sort of things that Gem does - e.g. create a wrapper script that calls the
executable script in the gem. It even uses the same shebang approach because the sheband method
has been lifted and adapted from rubygems. See the method description to understand
all of the options: {Jeni::Actions#shebang}.

However, if you are working on a platform that supports multiple rubies then I would
recommend you leave selection of which ruby to the system. The only way this appears to
be possible is with a custom shebang (add "custom_shebang: $env ruby" to your gemrc). This
does not take any notice of options in the original shebang, but if they are universal you
could always add them to you custom shebang? This is because the rubygems does pick up
the original script's shebang but always tampers with the "ruby" bit. e.g. if it
was /usr/bin/env ruby it changes the ruby to ruby19 (even /usr/bin/ruby19?).

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

Jeni stands for "Jumpin Ermin's Nifty Installer". Don't ask.


## Dependencies

A ruby compiler >= 1.8.7. Currently works on 1.9.3 and 2.0.0.

Check the {file:Gemfile} for other dependencies.

### Documentation

Documentation is best viewed using Yard. Documentation is available from 
[Rubydoc](http://rubydoc.info/github/osburn-sharp/jeni/frames)

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

Details of any unresolved bugs and change requests are in {file:Bugs.rdoc Bugs}. 
Issues can be logged and tracked through
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