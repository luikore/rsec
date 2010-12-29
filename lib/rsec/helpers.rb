# coding: utf-8
# ------------------------------------------------------------------------------
# Helpers(combinators) to construct parser

module Rsec
  # these are not callable from a parser
  module Helpers
    # --------------------------------------------------------------------------
    # Unary

    # lazy parser
    def lazy &p
      Lazy[p]
    end

    # dynamic parser
    def dynamic &p
      Dynamic[p]
    end

    # value parser (accept any input, don't advance ctx and return value x)
    def value x
      Value[x]
    end

    # beginning of line parser
    def bol default_return=SKIP
      Bol[default_return]
    end
    
    # move scan pos n characters<br/>
    # n can be negative
    def skip_n n
      SkipN[n]
    end

    def one_of str
      raise 'should be string' unless str.is_a?(String)
      raise 'str len should > 0' if str.empty?
      raise 'str should be ascii' unless str.bytesize == str.size
      OneOf[str.dup.freeze]
    end

    def one_of_ str
      raise 'should be string' unless str.is_a?(String)
      raise 'str len should > 0' if str.empty?
      raise 'str should be ascii' unless str.bytesize == str.size
      raise 'str should not contain space' if str =~ /\s/
      SpacedOneOf[str.dup.freeze]
    end

  end

  # robust
  Helper = Helpers

  # ----------------------------------------------------------------------------
  # Binary

  # when self failed, use other
  def | other
    other = Rsec.make_parser other
    if is_a?(Or)
      Or[*self, other] # note: struct has a * behavior
    else
      Or[self, other]
    end
  end

  # wrap(parser, '()') is equivalent to '('.r >> parser << ')' <br/>
  # str should be 2 ascii chars (begin-char and end-char)
  def wrap str
    raise 'should be string' unless str.is_a?(String)
    raise 'str should be 2 ascii chars (begin-char and end-char)' unless (str.bytesize == 2 and str.size == 2)
    Wrap[self, str.dup.freeze]
  end

  # wrap_(parser, '()') is equivalent to /\(\s*/.r >> parser << /\s*\)/
  # str should be 2 ascii chars (begin-char and end-char)
  def wrap_ str
    raise 'should be string' unless str.is_a?(String)
    raise 'str should be 2 ascii chars (begin-char and end-char)' unless (str.bytesize == 2 and str.size == 2)
    WrapSpace[self, str.dup.freeze]
  end

  # fall to other
  def >> other
    other = Rsec.make_parser other
    FallRight[self, other]
  end

  # fall to self
  def << other
    other = Rsec.make_parser other
    FallLeft[self, other]
  end

  # transform result
  def map &p
    Map[self, p]
  end

  # "p.join('+')" parses strings like "p+p+p+p+p".<br/>
  # Note that at least 1 of p appears in the string.<br/>
  # Sometimes it is useful to reverse the joining:<br/>
  # /\s*/.r.skip.join('p') parses string like " p p  p "
  def join inter
    inter = Rsec.make_parser inter
    Join[self, inter]
  end

  # repeat n or in a range<br/>
  def * n
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
  end

  # repeat at least n<br/>
  # [n, inf)
  def ** n
    raise "invalid n: #{n}" if n < 0
    RepeatAtLeastN[self, n]
  end

  # look ahead
  def & other
    other = Rsec.make_parser other
    LookAhead[self, other]
  end

  # negative look ahead
  def ^ other
    other = Rsec.make_parser other
    NegativeLookAhead[self, other]
  end

  # when parsing failed, show msg instead of default message
  def fail msg
    Fail[self, msg]
  end

  # infix operator table implemented with Shunting-Yard algorithm<br/>
  # call-seq:
  # <pre>
  #     /\w+/.r.join_infix_operators \
  #       space: ' ',
  #       left: {'+' => 30, '*' => 40},
  #       right: {'=' => 20}
  # </pre>
  # options:
  # <pre>
  #     space: sets space_before and space_after at the same time
  #     space_before: skip the space before operator
  #     space_after: skip the space after operator
  #     left: left associative operator table, in the form of "{operator => precedence}"
  #     right: right associative operator table
  # </pre>
  # NOTE: outputs reverse-polish-notation(RPN)<br/>
  # NOTE: should put "**" before "*"
  def join_infix_operators opts={}
    # TODO: also make AST output available?
    # TODO: now operator acceps string only, make it parser aware
    ShuntingYard.new self, opts
  end

  # ----------------------------------------------------------------------------
  # Unary

  # should be eof after parse
  def eof
    Eof[self]
  end

  # maybe parser<br/>
  # appears 0 or 1 times, result is not wrapped in an array
  def maybe
    Maybe[self]
  end
  alias _? maybe
  
  # to skip node
  def skip
    Skip[self]
  end

  # return a parser that caches parse result, may optimize performance
  def cached
    Cached[self]
  end

  # ensure x is a parser
  def Rsec.make_parser x
    return x if x.is_a?(::Rsec)
    x = x.send(TO_PARSER_METHOD) if x.respond_to?(TO_PARSER_METHOD)
    raise "type mismatch, <#{x}> should be a Rsec" unless x.is_a?(::Rsec)
    x
  end
end

# String#r: convert self to parser
class String
  # convienient string-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD do
    ::Rsec::Pattern[/#{Regexp.escape self}/]
  end
end

# Regexp#r: convert self to parser
class Regexp
  # convienient regexp-to-parser transformer
  define_method ::Rsec::TO_PARSER_METHOD do
    ::Rsec::Pattern[self]
  end
end

# Array#r: convert self to sequence parser
class Array
  # convienient regexp-to-parser transformer<br/>
  # if a :skip option is given, the string matching the pattern between elems will be neglected<br/>
  # e.g. 
  # <pre>
  #   ['a', 'b', 'c'].r skip:(/\ /).parse('a b c')
  #   # => ['a', 'b', 'c']
  # </pre>
  if ::Rsec::TO_PARSER_METHOD == :r
    def r opts={}
      if opts[:skip]
        parser = ::Rsec::SeqInnerSkip[*self.map{|p|::Rsec.make_parser p}]
        parser.inner_skip = ::Rsec.make_parser opts[:skip]
      else
        parser = ::Rsec::Seq[*self.map{|p|::Rsec.make_parser p}]
      end
      parser
    end
  else
    def rsec opts={}
      if opts[:skip]
        parser = ::Rsec::SeqInnerSkip[*self.map{|p|::Rsec.make_parser p}]
        parser.inner_skip = ::Rsec.make_parser opts[:skip]
      else
        parser = ::Rsec::Seq[*self.map{|p|::Rsec.make_parser p}]
      end
      parser
    end
  end
end

