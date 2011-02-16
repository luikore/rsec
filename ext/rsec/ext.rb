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

  # optimize one_of() for byte-only string
  class OneOfByte < OneOf
  end

  # optimize one_of_() for byte-only string
  class SpacedOneOfByte < SpacedOneOf
  end

  # optimize wrap() for byte-only string
  class WrapByte < Wrap
  end

  # optimize wrap_() for byte-only string
  class SpacedWrapByte < SpacedWrap
  end

  # overwrite prim initializer
  [PDouble, PInt32, PUnsignedInt32].each do |k|
    k.send :define_method, :initialize, ->l, r{
      self.left = l
      self.right = r
    }
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

