module Rsec
  # make skipping a string faster
  class SkipFixString < Unary
    def until
      SkipUntilPattern[Regexp.new Regexp.escape some()]
    end
  end

  # make normal string parsing faster
  class FixString < Unary
    def skip
      SkipFixString[some()]
    end
    def until
      UntilPattern[Regexp.new Regexp.escape some()]
    end
  end

  # make skipping a byte faster
  class SkipByte < Unary
    def until
      SkipUntilPattern[Regexp.new Regexp.escape some()]
    end
  end

  # make normal string parsing faster
  class Byte < Unary
    def skip
      SkipByte[some()]
    end
    def until
      UntilPattern[Regexp.new Regexp.escape some()]
    end
  end

  # combine fall and value
  class FallValue < Binary
  end

  module Helpers
    # primitive parser
    def prim type
      case type
      when :double; DOUBLE.new
      when :decimal_double; DECIMAL_DOUBLE.new
      when :unsigned_double; UNSIGNED_DOUBLE.new
      when :unsigned_decimal_double; UNSIGNED_DECIMAL_DOUBLE.new

      when :float; FLOAT.new
      when :decimal_float; DECIMAL_FLOAT.new
      when :unsigned_float; UNSIGNED_FLOAT.new
      when :unsigned_decimal_float; UNSIGNED_DECIMAL_FLOAT.new

      when :int32; INT32.new
      when :unsigned_int32; UNSIGNED_INT32.new
      when :int64; INT64.new
      when :unsigned_int64; UNSIGNED_INT64.new
      else; raise "invalid primitive type #{type}"
      end
    end
  end

  # redefine fall to other
  def >> other
    if other.is_a?(Value)
      FallValue[self, other.some]
    else
      other = Rsec.make_parser other
      FallRight[self, other]
    end
  end

  # redefine fall to self
  def << other
    if other.is_a?(Value)
      FallValue[self, other.some]
    else
      other = Rsec.make_parser other
      FallLeft[self, other]
    end
  end
end

class String
  # overwrite string-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD do
    if self.bytesize == 1
      ::Rsec::Byte[self]
    else
      ::Rsec::FixString[self]
    end
  end
end
