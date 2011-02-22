# coding: utf-8

module Rsec #:nodoc:
  # parser base
  module Parser
    # parses string<br/>
    # returns nil if unparsed
    def parse str, source_name='source'
      ctx = ParseContext.new str, source_name
      _parse ctx
    end

    # almost the same as parse<br/>
    # but raises SyntaxError
    def parse! str, source_name='source'
      ctx = ParseContext.new str, source_name
      ret = _parse ctx
      if INVALID[ret]
        raise ctx.generate_error source_name
      end
      ret
    end

    attr_accessor :name
    def inspect
      # TODO move
      @name ||= self.class.to_s[/\w+$/]
      case self
      when Lazy
        "<#{name}>"
      when Binary
        "<#{name} #{left.inspect} #{right.inspect}>"
      when Seq, Seq_, Branch
        # don't use redefined map!
        res = []
        each{|e| res << e.inspect}
        "<#{name} #{res.join ' '}>"
      when Unary
        "<#{name} #{some.inspect}>"
      else
        "<#{name}>"
      end
    end
  end

  # parsers with 2 params base
  Binary = Struct.new :left, :right
  class Binary 
    include Parser
  end

  # parsers with 1 param base
  Unary = Struct.new :some
  class Unary
    include Parser
  end
end

require "rsec/parsers/misc"
require "rsec/parsers/seq"
require "rsec/parsers/prim"
require "rsec/parsers/join"
require "rsec/parsers/repeat"

