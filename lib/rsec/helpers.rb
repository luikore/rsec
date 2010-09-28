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
    def bol default_return=:_skip_
      Bol[default_return]
    end
    
    # move scan pos n characters<br/>
    # n can be negative
    def skip_n n
      SkipN[n]
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

  # trigger(call the given block) when parsed
  def on &p
    On[self, p]
  end

  # "p.ljoin('+')" parses things like "p+p+p+p+p"<br/>
  # note: at least 1 of p appears<br/>
  def join inter, space=nil
    space = \
      case space
      when String then /#{Regexp.escape space}/
      when Regexp, nil then space
      when Pattern, SkipPattern then space.some
      else raise 'invalid inter skip'
      end

    inter = Rsec.make_parser inter

    if space
      sj = SpacedJoin[self, inter]
      sj.space = space
      sj
    else
      Join[self, inter]
    end
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

  # put this in message when parsing failed
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
  # convienient regexp-to-parser transformer
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

