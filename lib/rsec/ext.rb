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

  class PDouble < Binary
  end
  class PFloat < Binary
  end
  class PInt32 < Binary
  end
  class PInt64 < Binary
  end
  class PUnsignedInt32 < Binary
  end
  class PUnsignedInt64 < Binary
  end

  module Helpers
    # primitive parser, returns nil if overflow or underflow. <br/>
    # There can be an optional '+' or '-' at the beginning of string except unsinged_int32 | unsinged_int64. <br/>
    # type can be one of:
    # <pre>
    #   :double
    #   :hex_double
    #   :float
    #   :hex_float
    #   :int32
    #   :int64
    #   :unsigned_int32
    #   :unsigned_int64
    # </pre>
    # options:
    # <pre>
    #   :allowed_sign => '+' or '-' or '' or '+-' (default is '+-')
    #   :allowed_signs   (same as :allowed_sign)
    #   :base => integer (integers only, default is 10)
    # </pre>
    def prim type, options={}
      base = options[:base]
      if [:double, :hex_double, :float, :hex_float].index base
        raise 'Floating points does not allow :base'
      end
      base ||= 10
      raise ':base should be integer' unless base.is_a?(Fixnum)
      raise "Base out of range #{base}" if base < 2 or base > 16
      
      sign_strategy = \
        case (options[:allowed_sign] or options[:allowed_signs])
        when nil, ''; 3
        when '+'; 2
        when '-'; 1
        when '+-', '-+'; 0
        else raise "allowed_sign should be one of nil, '', '+', '-', '+-', '-+'"
        end

      case type
      when :double; PDouble.new sign_strategy, false # decimal
      when :float;  PFloat.new sign_strategy, false
      when :hex_double; PDouble.new sign_strategy, true # hex
      when :hex_float;  PFloat.new sign_strategy, true
      when :int32;  PInt32.new sign_strategy, base
      when :int64;  PInt64.new sign_strategy, base
      when :unsigned_int32; PUnsignedInt32.new sign_strategy, base
      when :unsigned_int64; PUnsignedInt64.new sign_strategy, base
      else; raise "Invalid primitive type #{type}"
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
