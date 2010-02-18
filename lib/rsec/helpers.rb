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

  # ----------------------------------------------------------------------------
  # Binary

  # when self failed, use other
  def | other
    other = make_parser other
    if is_a?(Or)
      Or[*self, other] # note: struct has a * behavior
    else
      Or[self, other]
    end
  end

  # sequence parse, assoc right
  def > other
    other = make_parser other
    if is_a?(RSeq)
      RSeq[*self, other]
    else
      RSeq[self, other]
    end
  end

  # assoc with optional space
  def >> other
    other = make_parser other
    if is_a?(RSeq)
      RSeq[*self, SkipPattern[/\s*/], other]
    else
      RSeq[self, SkipPattern[/\s*/], other]
    end
  end

  # sequence parse, assoc left
  def < other
    other = make_parser other
    if is_a?(LSeq)
      LSeq[*self, other]
    else
      LSeq[self, other]
    end
  end

  # left assoc with optional space
  def << other
    other = make_parser other
    if is_a?(LSeq)
      LSeq[*self, SkipPattern[/\s*/], other]
    else
      LSeq[self, SkipPattern[/\s*/], other]
    end
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
  # result is left associative<br/>
  # note: at least 1 of p appears<br/>
  # note: it has nothing to do with SQL<br/>
  # hint: think about Array#join <br/>
  def ljoin inter
    inter = make_parser inter
    Ljoin[self, inter]
  end
  alias join ljoin

  # similar to ljoin<br/>
  # result is right associative
  def rjoin inter
    inter = make_parser inter
    Rjoin[self, inter]
  end

  # repeat n or in a range<br/>
  # when n < 0 or the range starts < 0, result is right associative
  def * n
    if n.is_a?(Range)
      if n.end > 0
        RepeatRange[self, n]
      else
        RepeatAtLeastN[self, n.begin]
      end
    else
      RepeatN[self, n]
    end
  end

  # repeat at least n<br/>
  # [n, inf)
  def ** n
    RepeatAtLeastN[self, n]
  end

  # look ahead
  def & other
    other = make_parser other
    LookAhead[self, other]
  end

  # negative look ahead
  def ^ other
    other = make_parser other
    NegativeLookAhead[self, other]
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

  # put this in message when parsing failed
  def fail msg
    Fail[self, msg]
  end

  # ensure x is a parser
  def make_parser x
    return x if x.is_a?(::Rsec)
    x = x.send(TO_PARSER_METHOD) if x.respond_to?(TO_PARSER_METHOD)
    raise "type mismatch, <#{x}> should be a Rsec" unless x.is_a?(::Rsec)
    x
  end
  private :make_parser
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

