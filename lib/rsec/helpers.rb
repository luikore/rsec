# coding: utf-8
# ------------------------------------------------------------------------------
# Helpers(combinators) to construct parser

module Rsec #:nodoc:

  # ------------------------------------------------------------------------------
  # these are not callable from a parser
  module Helpers
 
    # @ desc.helper
    #   Lazy parser is constructed when parsing starts. It is useful to reference a parser not defined yet
    # @ example
    #   parser = lazy{future}
    #   future = 'jim'.r
    #   assert_equal 'jim', parser.parse '12323'
    def lazy &p
      raise ArgumentError, 'lazy() requires a block' unless p
      Lazy[p]
    end
    
    # @ desc.helper
    #   Parses one of chars in str
    # @ example
    #   multiplicative = one_of '*/%'
    #   assert_equal '/', multiplicative.parse '/'
    #   assert_equal Rsec::INVALID, actualmultiplicative.parse '+'
    def one_of str, &p
      Rsec.assert_type str, String
      raise ArgumentError, 'str len should > 0' if str.empty?
      one_of_klass =
        if (str.bytesize == str.size) and Rsec.const_defined?(:OneOfByte)
          # for C-ext
          OneOfByte
        else
          OneOf
        end
      one_of_klass[str.dup.freeze].map p
    end

    # @ desc.helper
    #   See also #one_of#, with leading and trailing optional breakable spaces
    # @ example
    #   additive = one_of_('+-')
    #   assert_equal '+', additive.parse('  +')
    def one_of_ str, &p
      Rsec.assert_type str, String
      raise ArgumentError, 'str len should > 0' if str.empty?
      raise ArgumentError, 'str should be ascii' unless str.bytesize == str.size
      raise ArgumentError, 'str should not contain space' if str =~ /\s/
      spaced_one_of_klass =
        if (str.bytesize == str.size) and Rsec.const_defined?(:OneOfByte_)
          # for C-ext
          OneOfByte_
        else
          OneOf_
        end
      spaced_one_of_klass[str.dup.freeze].map p
    end

    # @ desc.helper
    #   Primitive parser, returns nil if overflow or underflow.
    #   There can be an optional '+' or '-' at the beginning of string except unsinged_int32 | unsinged_int64.
    #   type =
    #     :double |
    #     :hex_double |
    #     :int32 |
    #     :int64 |
    #     :unsigned_int32 |
    #     :unsigned_int64
    #   options:
    #     :allowed_sign => '+' | '-' | '' | '+-' (default '+-')
    #     :allowed_signs => (same as :allowed_sign)
    #     :base => integer only (default 10)
    # @ example
    #   p = prim :double
    #   assert_equal 1.23, p.parse('1.23')
    #   p = prim :double, allowed_sign: '-'
    #   assert_equal 1.23, p.parse('1.23')
    #   assert_equal -1.23, p.parse('-1.23')
    #   assert_equal Rsec::INVALID, p.parse('+1.23')
    #   p = prim :int32, base: 36
    #   assert_equal 49713, p.parse('12cx')
    def prim type, options={}, &p
      base = options[:base]
      if [:double, :hex_double].index base
        raise 'Floating points does not allow :base'
      end
      base ||= 10
      Rsec.assert_type base, Fixnum
      unless (2..36).include? base
        raise RangeError, ":base should be in 2..36, but got #{base}"
      end
      
      sign_strategy = \
        case (options[:allowed_sign] or options[:allowed_signs])
        when nil, '+-', '-+'; 3
        when '+'; 2
        when '-'; 1
        when ''; 0
        else raise "allowed_sign should be one of nil, '', '+', '-', '+-', '-+'"
        end

      parser = \
        case type
        when :double; PDouble.new sign_strategy, false # decimal
        when :hex_double; raise "Removed because Ruby 1.9.3 removed float from hex" # PDouble.new sign_strategy, true # hex
        when :int32;  PInt32.new sign_strategy, base
        when :int64;  PInt64.new sign_strategy, base
        when :unsigned_int32;
          raise 'unsigned int not allow - sign' if options[:allowed_signs] =~ /-/
          PUnsignedInt32.new sign_strategy, base
        when :unsigned_int64;
          raise 'unsigned int not allow - sign' if options[:allowed_signs] =~ /-/
          PUnsignedInt64.new sign_strategy, base
        else
          raise "Invalid primitive type #{type}"
        end
      parser.map p
    end

    # @ desc.helper
    #   Sequence parser
    # @ example
    #   assert_equal ['a', 'b', 'c'], actualseq('a', 'b', 'c').parse('abc')
    def seq *xs, &p
      xs.map! {|x| Rsec.make_parser x }
      Seq[xs].map p
    end

    # @ desc.helper
    #   Sequence parser with skippable pattern(or parser)
    #   option
    #     :skip default= /\s*/
    # @ example
    #   assert_equal ['a', 'b', 'c'], actualseq_('a', 'b', 'c', skip: ',').parse('a,b,c')
    def seq_ *xs, &p
      skipper = 
        if (xs.last.is_a? Hash)
          xs.pop[:skip]
        end
      skipper = skipper ? Rsec.make_parser(skipper) : /\s*/.r
      xs.map! {|x| Rsec.make_parser x }
      first, *rest = xs
      raise 'sequence should not be empty' unless first
      Seq_[first, rest, skipper].map p
    end

    # @ desc.helper
    #   A symbol is something wrapped with optional space
    def symbol pattern, skip=/\s*/, &p
      pattern = Rsec.make_parser pattern
      skip = Rsec.try_skip_pattern Rsec.make_parser skip
      SeqOne[[skip, pattern, skip], 1].map p
    end

    # @ desc.helper
    #   A word is wrapped with word boundaries
    # @ example
    #   assert_equal ['yes', '3'], seq('yes', '3').parse('yes3')
    #   assert_equal INVALID, seq(word('yes'), '3').parse('yes3')
    def word pattern, &p
      parser = Rsec.make_parser pattern
      # TODO check pattern type
      Pattern[/\b#{parser.some}\b/].map p
    end
  end # helpers

  # robust
  Helper = Helpers

  # ------------------------------------------------------------------------------
  # combinators attached to parsers

  module Parser #:nodoc:

    # @ desc
    #   Transform result
    # @ example
    #   parser = /\w+/.r.map{|word| word * 2}
    #   assert_equal 'hellohello', parser.parse!('hello')
    def map lambda_p=nil, &p
      return self if (lambda_p.nil? and p.nil?)
      p = lambda_p || p
      raise TypeError, 'should give a proc or lambda' unless (p.is_a? Proc)
      Map[self, p]
    end

    # @ desc
    #   "p.join('+')" parses strings like "p+p+p+p+p".
    #   Note that at least 1 of p appears in the string.
    #   Sometimes it is useful to reverse the joining:
    #   /\s*/.r.join('p').odd parses string like " p p  p "
    def join inter, &p
      inter = Rsec.make_parser inter
      Join[self, inter].map p
    end

    # @ desc
    #   Branch parser, note that rsec is a PEG parser generator,
    #   beware of the difference between PEG and CFG.
    def | y, &p
      y = Rsec.make_parser y
      arr =
        if (is_a?(Branch) and !p)
          [*some, y]
        else
          [self, y]
        end
      Branch[arr].map p
    end

    # @ desc
    #   Repeat n or in a range.
    #   If range.end &lt; 0, repeat at least range.begin
    #   (Infinity and -Infinity are considered)
    def * n, &p
      # FIXME if self is an epsilon parser, will cause infinite loop
      parser =
        if n.is_a?(Range)
          raise "invalid n: #{n}" if n.begin < 0
          Rsec.assert_type n.begin, Integer
          end_inf = (n.end.infinite? rescue false)
          (Rsec.assert_type n.end, Integer) unless end_inf
          if n.end > 0
            RepeatRange[self, n]
          else
            RepeatAtLeastN[self, n.begin]
          end
        else
          Rsec.assert_type n, Integer
          raise "invalid n: #{n}" if n < 0
          RepeatN[self, n]
        end
      parser.map p
    end

    # @ desc
    #   Appears 0 or 1 times, result is wrapped in an array
    # @ example
    #   parser = 'a'.r.maybe
    #   assert_equal ['a'], parser.parse('a')
    #   assert_equal [], parser.parse('')
    def maybe &p
      Maybe[self].map &p
    end
    alias _? maybe

    # @ desc
    #   Kleen star, 0 or more any times
    def star &p
      self.* (0..-1), &p
    end

    # @ desc
    #   Lookahead predicate, note that other can be a very complex parser
    def & other, &p
      other = Rsec.make_parser other
      LookAhead[self, other].map p
    end

    # @ desc
    #   Negative lookahead predicate
    def ^ other, &p
      other = Rsec.make_parser other
      NegativeLookAhead[self, other].map p
    end

    # @ desc
    #   When parsing failed, show "expect tokens" error
    def fail *tokens, &p
      return self if tokens.empty?
      Fail[self, tokens].map p
    end
    alias expect fail

    # @ desc
    #   Short for seq_(parser, other)[1]
    def >> other, &p
      other = Rsec.make_parser other
      left = Rsec.try_skip_pattern self
      SeqOne_[left, [other], SkipPattern[/\s*/], 1].map p
    end

    # @ desc
    #   Short for seq_(parser, other)[0]
    def << other, &p
      other = Rsec.make_parser other
      right = Rsec.try_skip_pattern other
      SeqOne_[self, [right], SkipPattern[/\s*/], 0].map p
    end

    # @ desc
    #   Should be end of input after parse
    def eof &p
      Eof[self].map p
    end

    # @ desc
    #   Packrat parser combinator, returns a parser that caches parse result, may optimize performance
    def cached &p
      Cached[self].map p
    end
  end

  # ------------------------------------------------------------------------------
  # additional helper methods for special classes

  class Seq
    # @ desc.seq, seq_
    #   Returns the parse result at idx, shorter and faster than map{|array| array[idx]}
    # @ example
    #   assert_equal 'b', seq('a', 'b', 'c')[1].parse('abc')
    def [] idx, &p
      raise 'index out of range' if (idx >= some().size or idx < 0)
      # optimize
      parsers = some().map.with_index do |p, i|
        i == idx ? p : Rsec.try_skip_pattern(p)
      end
      SeqOne[parsers, idx].map p
    end

    # @ desc.seq, seq_, join, join.even, join.odd
    #   If parse result contains only 1 element, return the element instead of the array
    def unbox &p
      Unbox[self].map p
    end

    # @ desc
    #   Think about "innerHTML"!
    # @ example
    #   parser = seq('&lt;b&gt;', /[\w\s]+/, '&lt;/b&gt;').inner
    #   parser.parse('&lt;b&gt;the inside&lt;/b&gt;')
    def inner &p
      Inner[self].map p
    end
  end

  class Seq_
    def [] idx, &p
      raise 'index out of range' if idx > rest.size or idx < 0
      # optimize parsers, use skip if possible
      new_first = (0 == idx ? first : Rsec.try_skip_pattern(first))
      new_rest = rest().map.with_index do |p, i|
        # NOTE rest start with 1
        (i+1) == idx ? p : Rsec.try_skip_pattern(p)
      end
      SeqOne_[new_first, new_rest, skipper, idx].map p
    end

    def unbox &p
      Unbox[self].map p
    end

    def inner &p
      Inner[self].map p
    end
  end

  class Join
    def unbox &p
      Unbox[self].map p
    end

    # @ desc.join
    #   Only keep the even(left, token) parts
    def even &p
      JoinEven[left, Rsec.try_skip_pattern(right)].map p
    end

    # @ desc.join
    #   Only keep the odd(right, inter) parts
    def odd &p
      JoinOdd[Rsec.try_skip_pattern(left), right].map p
    end
  end

  class JoinEven
    def unbox &p
      Unbox[self].map p
    end
  end

  class JoinOdd
    def unbox &p
      Unbox[self].map p
    end
  end

  class Pattern
    # @ desc.r
    #   Scan until the pattern happens
    def until &p
      UntilPattern[some()].map p
    end
  end

  # ------------------------------------------------------------------------------
  # helper methods for parser generation

  # ensure x is a parser
  def Rsec.make_parser x
    return x if x.is_a?(Parser)
    x = x.send(TO_PARSER_METHOD) if x.respond_to?(TO_PARSER_METHOD)
    Rsec.assert_type x, Parser
    x
  end

  # type assertion
  def Rsec.assert_type obj, type
    (raise TypeError, "#{obj} should be a #{type}") unless (obj.is_a? type)
  end

  # try to convert Pattern -> SkipPattern
  def Rsec.try_skip_pattern p
    # for C-ext
    if Rsec.const_defined?(:FixString) and p.is_a?(FixString)
      return SkipPattern[/#{Regexp.escape p.some}/]
    end

    case p
    when Pattern
      SkipPattern[p.some]
    when UntilPattern
      SkipUntilPattern[p.some]
    else
      p
    end
  end
end

class String #:nodoc:
  # String#r: convert self to parser
  # convienient string-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD, ->(*expects, &p){
    ::Rsec::Pattern[/#{Regexp.escape self}/].fail(*expects).map p
  }
end

class Regexp #:nodoc:
  # Regexp#r: convert self to parser
  # convienient regexp-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD, ->(*expects, &p){
    ::Rsec::Pattern[self].fail(*expects).map p
  }
end

