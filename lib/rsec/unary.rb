# coding: utf-8
# ------------------------------------------------------------------------------
# Unary Combinators

module Rsec
  Unary = Struct.new :some
  # unary combinator base
  class Unary
    include ::Rsec
  end

  # matches a pattern
  class Pattern < Unary
    def _parse ctx
      ctx.scan some() or INVALID
    end

    def until
      UntilPattern[some()]
    end

    def skip
      SkipPattern[some()]
    end
  end

  # returns a value for any input
  class Value < Unary
    def _parse ctx
      some()
    end
  end

  # matches beginning of line
  class Bol < Unary
    def _parse ctx
      ctx.bol ? some() : INVALID
    end
  end
  
  # should be end-of-file after parsing
  class Eof < Unary
    def _parse ctx
      ret = some()._parse ctx
      ctx.eos? ? ret : INVALID
    end
  end
  
  # matches 0 or 1 appearence
  class Maybe < Unary
    def _parse ctx
      pos = ctx.pos
      res = some()._parse(ctx)
      if INVALID[res]
        ctx.pos = pos
        return SKIP
      end
      res
    end
  end

  # skip parser<br/>
  # optimize for pattern
  class SkipPattern < Unary
    def _parse ctx
      return INVALID unless ctx.skip some()
      SKIP
    end
  end

  # skip parser
  class Skip < Unary
    def _parse ctx
      return INVALID if INVALID[some()._parse ctx]
      SKIP
    end
  end

  # skip n<br/>
  # fails when out of range.
  class SkipN < Unary
    def _parse ctx
      ctx.pos = ctx.pos + some()
      SKIP
    rescue RangeError # index may out of range
      INVALID
    end
  end

  # scan until the pattern<br/>
  # only constructable for Patterns
  class UntilPattern < Unary
    def _parse ctx
      ctx.scan_until some() or INVALID
    end

    def skip
      SkipUntilPattern[some()]
    end
  end

  # skip until the pattern<br/>
  # only constructable for Patterns
  class SkipUntilPattern < Unary
    def _parse ctx
      ctx.skip_until(some()) ? SKIP : INVALID
    end
  end

  class OneOf < Unary
    def _parse ctx
      return INVALID if ctx.eos?
      chr = ctx.getch
      if some().index(chr)
        chr
      else
        ctx.pos = ctx.pos - 1
        INVALID
      end
    end
  end

  class SpacedOneOf < Unary
    def _parse ctx
      save_point = ctx.pos
      ctx.skip /\s*/
      return INVALID if ctx.eos?
      chr = ctx.getch
      unless some().index(chr)
        ctx.pos = save_point
        return INVALID
      end
      ctx.skip /\s*/
      chr
    end
  end

  # dynamic parser
  class Dynamic < Unary
    def _parse ctx
      some()[]._parse ctx
    end
  end

  # sometimes a variable is not defined yet<br/>
  # lazy is used to capture it later
  # NOTE the value is captured the first time it is called
  #      if want to capture it everytime, use dynamic
  class Lazy < Unary
    def _parse ctx
      @some ||= some()[]
      @some._parse ctx
    end
  end
  
  # parse result is cached in ctx.
  # may improve performance
  class Cached
    include ::Rsec
    
    def self.[] parser
      self.new parser
    end
    
    def initialize parser
      @parser = parser
      @salt = object_id() << 32
    end
    
    def _parse ctx
      key = ctx.pos | @salt
      cache = ctx.cache
      # result maybe nil, so don't use ||=
      if cache.has_key? key
        ret, pos = cache[key]
        ctx.pos = pos
        ret
      else
        ret = @parser._parse ctx
        pos = ctx.pos
        cache[key] = [ret, pos]
        ret
      end
    end
  end
end

