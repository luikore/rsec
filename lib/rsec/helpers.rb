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
    def bol x=:_skip_
      Bol[x]
    end

    # move scan pos n characters<br/>
    # can be negative
    def skip_n n
      SkipN[n]
    end

    # --------------------------------------------------------------------------
    # "Zero-nary"

    def space
      SkipPattern[/\s+/]
    end

    def spacee
      SkipPattern[/\s*/]
    end

    def int
      Pattern[/[+-]?\d+/]
    end

    def float
      Pattern[/[+-]?\d+(\.\d+)?/]
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

  # parses things like "self inter self inter self"<br/>
  # result is left associative<br/>
  # at least 1 of self appears (doesn't match "" if left doesn't match "", see also ljoin_)<br/>
  # note: it has nothing to do with SQL<br/>
  # hint: think about Array#join <br/>
  def ljoin inter
    inter = make_parser inter
    Ljoin[self, inter]
  end
  alias join ljoin

  # similar to ljoin, but also matches ""
  def ljoin_ inter
    inter = make_parser inter
    Ljoin_[self, inter]
  end
  alias join_ ljoin

  # similar to ljoin<br/>
  # result is right associative
  def rjoin inter
    inter = make_parser inter
    Rjoin[self, inter]
  end

  # similar to ljoin, but also matches ""
  def rjoin_ inter
    inter = make_parser inter
    Rjoin_[self, inter]
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

  # to skip node
  def skip
    Skip[self]
  end

  # wraps parse result, then it won't splat
  def wrap
    Wrap[self]
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

