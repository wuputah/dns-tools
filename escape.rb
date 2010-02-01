# escape.rb - escape/unescape library for several formats
#
# Copyright (C) 2006,2007,2009 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

module Escape
  module_function

  class StringWrapper
    class << self
      alias new_no_dup new
      def new(str)
        new_no_dup(str.dup)
      end
    end

    def initialize(str)
      @str = str
    end

    def escaped_string
      @str.dup
    end

    alias to_s escaped_string

    def inspect
      "\#<#{self.class}: #{@str}>"
    end

    def ==(other)
      other.class == self.class && @str == other.instance_variable_get(:@str)
    end
    alias eql? ==

    def hash
      @str.hash
    end
  end

  class ShellEscaped < StringWrapper
  end

  # Escape.shell_command composes
  # a sequence of words to
  # a single shell command line.
  # All shell meta characters are quoted and
  # the words are concatenated with interleaving space.
  # It returns an instance of ShellEscaped.
  #
  #  Escape.shell_command(["ls", "/"]) #=> #<Escape::ShellEscaped: ls />
  #  Escape.shell_command(["echo", "*"]) #=> #<Escape::ShellEscaped: echo '*'>
  #
  # Note that system(*command) and
  # system(Escape.shell_command(command).to_s) is roughly same.
  # There are two exception as follows.
  # * The first is that the later may invokes /bin/sh.
  # * The second is an interpretation of an array with only one element: 
  #   the element is parsed by the shell with the former but
  #   it is recognized as single word with the later.
  #   For example, system(*["echo foo"]) invokes echo command with an argument "foo".
  #   But system(Escape.shell_command(["echo foo"]).to_s) invokes "echo foo" command
  #   without arguments (and it probably fails).
  def shell_command(command)
    s = command.map {|word| shell_single_word(word) }.join(' ')
    ShellEscaped.new_no_dup(s)
  end

  # Escape.shell_single_word quotes shell meta characters.
  # It returns an instance of ShellEscaped.
  #
  # The result string is always single shell word, even if
  # the argument is "".
  # Escape.shell_single_word("") returns #<Escape::ShellEscaped: ''>.
  #
  #  Escape.shell_single_word("") #=> #<Escape::ShellEscaped: ''>
  #  Escape.shell_single_word("foo") #=> #<Escape::ShellEscaped: foo>
  #  Escape.shell_single_word("*") #=> #<Escape::ShellEscaped: '*'>
  def shell_single_word(str)
    if str.empty?
      ShellEscaped.new_no_dup("''")
    elsif %r{\A[0-9A-Za-z+,./:=@_-]+\z} =~ str
      ShellEscaped.new(str)
    else
      result = ''
      str.scan(/('+)|[^']+/) {
        if $1
          result << %q{\'} * $1.length
        else
          result << "'#{$&}'"
        end
      }
      ShellEscaped.new_no_dup(result)
    end
  end

end
