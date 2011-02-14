module Rsec #:nodoc:
  # make skipping a string faster
  class SkipFixString < Unary
    def until &p
      parser = SkipUntilPattern[Regexp.new Regexp.escape some()]
      p ? parser.map(&p) : parser
    end
  end

  # make normal string parsing faster
  class FixString < Unary
    def skip &p
      parser = SkipFixString[some()]
      p ? parser.map(&p) : parser
    end
    def until &p
      parser = UntilPattern[Regexp.new Regexp.escape some()]
      p ? parser.map(&p) : parser
    end
  end

  # make skipping a byte faster
  class SkipByte < Unary
    def until &p
      parser = SkipUntilPattern[Regexp.new Regexp.escape some()]
      p ? parser.map(&p) : parser
    end
  end

  # make normal string parsing faster
  class Byte < Unary
    def skip &p
      parser = SkipByte[some()]
      p ? parser.map(&p) : parser
    end
    def until &p
      parser = UntilPattern[Regexp.new Regexp.escape some()]
      p ? parser.map(&p) : parser
    end
  end
end

# require the so
require "rsec/predef"

class String
  # overwrite string-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD, ->(&p){
    parser = \
      if self.bytesize == 1
        ::Rsec::Byte[self]
      else
        ::Rsec::FixString[self]
      end
    p ? parser.map(&p) : parser
  }
end

