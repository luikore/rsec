# coding: utf-8
# ------------------------------------------------------------------------------
# Helpers to make code cleaner

module Rsec
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
      RSeq[*self, /\s*/.r.skip, other]
    else
      RSeq[self, /\s*/.r.skip, other]
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
      LSeq[*self, /\s*/.r.skip, other]
    else
      LSeq[self, /\s*/.r.skip, other]
    end
  end

  # transform result
  def map &p
    Map[self, p]
  end

  # trigger when parsed
  def on &p
    On[self, p]
  end

  # parses things like "self inter self inter self"<br/>
  # result is left associative<br/>
  # note: it has nothing to do with SQL<br/>
  # hint 1: think about Array#join <br/>
  # hint 2: you'd better not return :_skip_ in map for left or right,
  # then the array is unified and easier to deal with.
  # there's no problem to return :_skip_ if you are clear what it is doing.
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

  # to skip node
  def skip
    if is_a?(Pattern)
      SkipPattern[some()] # optimize for pattern
    else
      Skip[self]
    end
  end

  # put this in message when parsing failed
  def fail msg
    Fail[self, msg]
  end

  # ensure x is a parser
  def make_parser x
    return x if x.is_a?(::Rsec)
    x = x.r if x.respond_to? :r
    raise "type mismatch, <#{x}> should be a Rsec" unless x.is_a?(::Rsec)
    x
  end
  private :make_parser
end

class String
  # convienient string-to-parser transformer
  def r
    ::Rsec::Pattern[/#{Regexp.escape self}/]
  end
end

class Regexp
  # convienient regexp-to-parser transformer
  def r
    ::Rsec::Pattern[self]
  end
end

# lazy parser
def lazy &p
  ::Rsec::Lazy[p]
end

