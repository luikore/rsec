# coding: utf-8
# ------------------------------------------------------------------------------
# x-nary combinators

module Rsec #:nodoc:

  # sequence combinator<br/>
  # result in an array
  class Seq < Struct.new(:parsers)
    include ::Rsec

    def _parse ctx
      ret = []
      parsers.each do |e|
        res = e._parse ctx
        return INVALID if INVALID[res]
        ret << res unless SKIP[res]
      end
      ret
    end
  end


  # sequence combinator<br/>
  # the result is the result of the parser at idx
  class SeqOne < Struct.new(:parsers, :idx)
    include ::Rsec

    def _parse ctx
      ret = INVALID
      parsers.each_with_index do |p, counter|
        res = p._parse ctx
        return INVALID if INVALID[res]
        ret = res if counter == idx
      end
      ret
    end
  end

  # skips skipper between tokens
  class Seq_ < Struct.new(:first, :rest, :skipper)
    include ::Rsec

    def _parse ctx
      res = first._parse ctx
      return INVALID if INVALID[res]
      ret = [res]

      rest.each do |e|
        return INVALID if INVALID[skipper._parse ctx]
        res = e._parse ctx
        return INVALID if INVALID[res]
        ret << res unless SKIP[res]
      end
      ret
    end
  end
  
  # skips skipper between tokens
  class SeqOne_ < Struct.new(:first, :rest, :skipper, :idx)
    include ::Rsec

    def _parse ctx
      res = first._parse ctx
      return INVALID if INVALID[res]
      ret = res if 0 == idx

      rest.each_with_index do |p, counter|
        return INVALID if INVALID[skipper._parse ctx]
        res = p._parse ctx
        return INVALID if INVALID[res]
        ret = res if counter == idx
      end
      ret
    end
  end

  # branch combinator<br/>
  # result in one of the members, or INVALID
  class Branch < Struct.new(:parsers)
    include ::Rsec

    def _parse ctx
      save_point = ctx.pos
      parsers.each do |e|
        res = e._parse ctx
        return res unless INVALID[res]
        ctx.pos = save_point
      end
      INVALID
    end
  end

end
