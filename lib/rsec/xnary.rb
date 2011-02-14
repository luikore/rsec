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
      counter = 0
      parsers.each do |p|
        res = p._parse ctx
        return INVALID if INVALID[res]
        if INVALID[ret]
          ret = res if counter == idx and ! SKIP[res]
        end
        counter += 1 unless SKIP[res]
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
  
  # NOTE the skipped element will not be counted
  class SeqOne_ < Struct.new(:first, :rest, :skipper, :idx)
    include ::Rsec

    def _parse ctx
      res = first._parse ctx
      return INVALID if INVALID[res]
      counter = 0
      ret = counter == idx ? res : INVALID

      rest.each do |p|
        return INVALID if INVALID[skipper._parse ctx]
        res = p._parse ctx
        return INVALID if INVALID[res]
        if INVALID[ret] # if we got one ret, don't do it anymore
          ret = res if counter == idx and ! SKIP[res]
        end
        counter += 1 unless SKIP[res]
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
      INVALID # don't forget to fail it when none of the elements matches
    end
  end

end
