module Rsec #:nodoc:

  # make normal string parsing faster
  class FixString < Unary
    def until &p
      UntilPattern[Regexp.new Regexp.escape some()].map &p
    end

    def as_word &p
      Pattern[/\b#{Regexp.escape some}\b/].map p
    end

    # wrap with optional space by default
    def wrap skip=/\s*/, &p
      skip = Rsec.try_skip_pattern Rsec.make_parser skip
      SeqOne[[skip, Pattern[/\b#{Regexp.escape some}\b/], skip], 1]
    end
  end

  # optimize one_of() for byte-only string
  class OneOfByte < OneOf
  end

  # optimize one_of_() for byte-only string
  class OneOfByte_ < OneOf_
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
  define_method ::Rsec::TO_PARSER_METHOD, ->(*expects, &p){
    parser = ::Rsec::FixString[self]
    parser.fail(*expects).map &p
  }
end

