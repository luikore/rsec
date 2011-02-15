# coding: utf-8
# ------------------------------------------------------------------------------
# Helpers(combinators) to construct parser

module Rsec #:nodoc:
  # these are not callable from a parser
  module Helpers
    # --------------------------------------------------------------------------
    # Unary

    # lazy parser
    def lazy &p
      raise 'lazy() requires a block' unless p
      Lazy[p]
    end

    # beginning of line parser
    def bol default_return=SKIP, &p
      Bol[default_return].map p
    end
    
    # move scan pos n characters<br/>
    # n can be negative
    def skip_n n, &p
      SkipN[n].map p
    end

    def one_of str, &p
      raise 'should be string' unless str.is_a?(String)
      raise 'str len should > 0' if str.empty?
      raise 'str should be ascii' unless str.bytesize == str.size
      OneOf[str.dup.freeze].map p
    end

    def one_of_ str, &p
      raise 'should be string' unless str.is_a?(String)
      raise 'str len should > 0' if str.empty?
      raise 'str should be ascii' unless str.bytesize == str.size
      raise 'str should not contain space' if str =~ /\s/
      SpacedOneOf[str.dup.freeze].map p
    end

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
    def prim type, options={}, &p
      base = options[:base]
      if [:double, :hex_double, :float, :hex_float].index base
        raise 'Floating points does not allow :base'
      end
      base ||= 10
      raise ':base should be integer' unless base.is_a?(Fixnum)
      raise "Base out of range #{base}" if base < 2 or base > 16
      
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
        when :float;  PFloat.new sign_strategy, false
        when :hex_double; PDouble.new sign_strategy, true # hex
        when :hex_float;  PFloat.new sign_strategy, true
        when :int32;  PInt32.new sign_strategy, base
        when :unsigned_int32;
          raise 'unsigned int not allow - sign' if options[:allowed_signs] =~ /-/
          PUnsignedInt32.new sign_strategy, base
        # when :int64;  PInt64.new sign_strategy, base
        # when :unsigned_int64; PUnsignedInt64.new sign_strategy, base
        else; raise "Invalid primitive type #{type}"
        end
      parser.map p
    end

    # sequence parser
    def seq *xs, &p
      xs.map! {|x| Rsec.make_parser x }
      Seq[xs].map p
    end

    # sequence parser with skippable pattern(or parser)
    # option
    #   :skip default= /\s*/.r.skip
    def seq_ *xs, &p
      skipper = 
        if (xs.last.is_a? Hash)
          xs.pop[:skip]
        end
      skipper = skipper ? Rsec.make_parser(skipper) : /\s*/.r.skip
      xs.map! {|x| Rsec.make_parser x }
      first, *rest = xs
      raise 'sequence should not be empty' unless first
      Seq_[first, rest, skipper].map p
    end

  end # helpers

  # robust
  Helper = Helpers

  # ----------------------------------------------------------------------------
  # Binary

  # wrap(parser, '()') is equivalent to '('.r >> parser << ')' <br/>
  # str should be 2 ascii chars (begin-char and end-char)
  def wrap str, &p
    raise 'should be string' unless str.is_a?(String)
    raise 'str should be 2 ascii chars (begin-char and end-char)' unless (str.bytesize == 2 and str.size == 2)
    Wrap[self, str.dup.freeze].map p
  end

  # wrap_(parser, '()') is equivalent to /\(\s*/.r >> parser << /\s*\)/
  # str should be 2 ascii chars (begin-char and end-char)
  def wrap_ str, &p
    raise 'should be string' unless str.is_a?(String)
    raise 'str should be 2 ascii chars (begin-char and end-char)' unless (str.bytesize == 2 and str.size == 2)
    SpacedWrap[self, str.dup.freeze].map p
  end

  # transform result
  def map lambda_p=nil, &p
    return self if (lambda_p.nil? and p.nil?)
    p = lambda_p || p
    raise 'should give a proc or lambda' unless (p.is_a? Proc)
    Map[self, p]
  end

  # "p.join('+')" parses strings like "p+p+p+p+p".<br/>
  # Note that at least 1 of p appears in the string.<br/>
  # Sometimes it is useful to reverse the joining:<br/>
  # /\s*/.r.skip.join('p') parses string like " p p  p "
  def join inter, &p
    inter = Rsec.make_parser inter
    Join[self, inter].map p
  end

  # branch
  def | y, &p
    y = Rsec.make_parser y
    arr =
      if (is_a?(Branch) and !p)
        [*parsers, y]
      else
        [self, y]
      end
    Branch[arr].map p
  end

  # repeat n or in a range<br/>
  def * n, &p
    parser =
      if n.is_a?(Range)
        raise "invalid n: #{n}" if n.begin < 0
        if n.end > 0
          RepeatRange[self, n]
        else
          RepeatAtLeastN[self, n.begin]
        end
      else
        raise "invalid n: #{n}" if n < 0
        RepeatN[self, n]
      end
    parser.map p
  end

  # repeat at least n<br/>
  # [n, inf)
  def ** n, &p
    raise "invalid n: #{n}" if n < 0
    RepeatAtLeastN[self, n].map p
  end

  # look ahead
  def & other, &p
    other = Rsec.make_parser other
    LookAhead[self, other].map p
  end

  # negative look ahead
  def ^ other, &p
    other = Rsec.make_parser other
    NegativeLookAhead[self, other].map p
  end

  # when parsing failed, show msg instead of default message
  def fail msg, &p
    Fail[self, msg].map p
  end

  # ----------------------------------------------------------------------------
  # Unary

  # should be eof after parse
  def eof &p
    Eof[self].map p
  end

  # maybe parser<br/>
  # appears 0 or 1 times, result is not wrapped in an array
  def maybe &p
    Maybe[self].map p
  end
  alias _? maybe
  
  # to skip node
  def skip &p
    Skip[self].map p
  end

  # return a parser that caches parse result, may optimize performance
  def cached &p
    Cached[self].map p
  end

  # ------------------------------------------------------------------------------
  # additional helper methods for special classes

  class Seq #:nodoc:
    def [] idx, &p
      raise 'index out of range' if (idx >= parsers.size or idx < 0)
      SeqOne[parsers, idx].map p
    end
  end

  class Seq_
    def [] idx, &p
      raise 'index out of range' if idx > rest.size or idx < 0
      SeqOne_[first, rest, skipper, idx].map p
    end
  end

  class Join
    # if the result of join contains only 1 element, return the elem instead of array
    def flatten
      map{|res| res.size == 1 ? res[0] : res }
    end
  end

  class Seq
    def flatten
      map{|res| res.size == 1 ? res[0] : res }
    end
  end

  class Seq_
    def flatten
      map{|res| res.size == 1 ? res[0] : res }
    end
  end

  class Pattern
    def until &p
      UntilPattern[some()].map p
    end

    def skip &p
      SkipPattern[some()].map p
    end
  end

  class UntilPattern
    def skip &p
      SkipUntilPattern[some()].map p
    end
  end

  # ensure x is a parser
  def Rsec.make_parser x
    return x if x.is_a?(::Rsec)
    x = x.send(TO_PARSER_METHOD) if x.respond_to?(TO_PARSER_METHOD)
    raise "type mismatch, <#{x}> should be an Rsec" unless x.is_a?(::Rsec)
    x
  end
end

class String
  # String#r: convert self to parser
  # convienient string-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD, ->(&p){
    ::Rsec::Pattern[/#{Regexp.escape self}/].map p
  }
end

class Regexp
  # Regexp#r: convert self to parser
  # convienient regexp-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD, ->(&p){
    ::Rsec::Pattern[self].map p
  }
end

