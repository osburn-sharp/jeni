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
# This file groups together all the errors for jeni.
# Preceed each class with a description of the error

module Jeni

  # A general class for all errors created by this project. All specific exceptions
  # should be children of this class
  class JeniError < RuntimeError; end

end