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
      ctx.scan some()
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
      ctx.bol ? some() : nil
    end
  end

  # skip parser<br/>
  # optimize for pattern
  class SkipPattern < Unary
    def _parse ctx
      ctx.skip(some()) and :_skip_
    end
  end

  # skip parser
  class Skip < Unary
    def _parse ctx
      some()._parse(ctx) and :_skip_
    end
  end

  # skip n<br/>
  # fails when out of range.
  class SkipN < Unary
    def _parse ctx
      ctx.pos = ctx.pos + some()
      :_skip_
    rescue RangeError # index may out of range
      nil
    end
  end

  # scan until the pattern<br/>
  # only constructable for Patterns
  class UntilPattern < Unary
    def _parse ctx
      ctx.scan_until some()
    end

    def skip
      SkipUntilPattern[some()]
    end
  end

  # skip until the pattern<br/>
  # only constructable for Patterns
  class SkipUntilPattern < Unary
    def _parse ctx
      ctx.skip_until(some()) and :_skip_
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
  class Cached < Unary
    def _parse ctx
      ctx.cache[self] ||= some()._parse(ctx)
    end
  end
end

