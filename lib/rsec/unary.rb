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

  # lazy parser<br/>
  # sometimes a variable is not defined yet<br/>
  # lazy is used to capture it later<br/>
  # it can also be used to construct parser binding
  class Lazy < Unary
    def _parse ctx
      some()[]._parse ctx
    end
  end
end

