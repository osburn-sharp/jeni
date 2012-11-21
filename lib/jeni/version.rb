# Created by Jevoom
#
# 21-Nov-2012
#   Generate templates to /tmp directory before transferring to target. Allow users to
#   generate to an alternative target directory, either with target= method or optparse.
#   Allow a block for optparse that passes through the optparse object to allow custom
#   options to be added. Add classify method so templates can convert e.g. project name
#   into a Ruby class (my_project -> MyProject).

module Jeni
  # version set to 0.2.3
  Version = '0.2.3'
  # date set to 21-Nov-2012
  Version_Date = '21-Nov-2012'
  #ident string set to: jeni-0.2.3 21-Nov-2012
  Ident = 'jeni-0.2.3 21-Nov-2012'
end
