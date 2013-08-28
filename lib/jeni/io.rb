#
#
# = Jeni
#
# == say method
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
  
  # Implementation mixin for IO related methods
  module IO
    
    # lookup that maps status symbol onto colours
    Colours = Hash.new(:white).merge({:ok=>:green, 
      :no_change=>:blue, 
      :warning=>:yellow, 
      :error=>:red
      })
    
    # lookup to map between symbols and responses
    Answers = Hash.new(false).merge({:yes=>'y', :no=>'n', :skip=>'s', :diff=>'d', :list=>'l'})
    AnswerKeys = Answers.values.join('')

    # set the length of the field in which verbs are set, right-justified
    VerbLen = 15
    
    # print out a message with nice indenting and colours
    def say(verb, message, status=:ok, quiet=false)
      mstr = verb.to_s.rjust(VerbLen) + ": "
      mstr << message
      mstr = mstr.send(Colours[status])
      puts mstr unless @quiet || quiet
      return mstr
    end
    
    # ask a question and give back the answer as a symbol using
    # the Answers constant hash to get the symbol
    def ask(question, default=:no, options=AnswerKeys)
      default = :no unless Answers.has_key?(default)
      return default if @pretend && ! @answer
      def_key = Answers[default]
      answers = (options.split(//) & AnswerKeys.split(//)).collect {|k| k == def_key ? k.upcase : k}.join('')     
      print "#{question}(#{answers})? "
      response = $stdin.gets.chomp.downcase
      if Answers.has_value?(response) then
        return Answers.key(response)
      else
        return default
      end
    end
    
    # check if the user wants to continue
    def continue?
      ans = ask("Do you want to continue?")
      raise JeniError unless ans == :yes
    end
    
  end #IO
end