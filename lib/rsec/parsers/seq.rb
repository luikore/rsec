module Rsec

  # sequence combinator<br/>
  # result in an array
  class Seq < Unary
    def _parse ctx
      some.map do |e|
        res = e._parse ctx
        return INVALID if INVALID[res]
        res
      end
    end
  end

  # sequence combinator<br/>
  # the result is the result of the parser at idx
  class SeqOne < Struct.new(:parsers, :idx)
    include Parser

    def _parse ctx
      ret = INVALID
      parsers.each_with_index do |p, i|
        res = p._parse ctx
        return INVALID if INVALID[res]
        ret = res if i == idx
      end
      ret
    end
  end

  # skips skipper between tokens
  class Seq_ < Struct.new(:first, :rest, :skipper)
    include Parser

    def _parse ctx
      res = first._parse ctx
      return INVALID if INVALID[res]
      ret = [res]

      rest.each do |e|
        return INVALID if INVALID[skipper._parse ctx]
        res = e._parse ctx
        return INVALID if INVALID[res]
        ret << res
      end
      ret
    end
  end
  
  # skips skipper between tokens
  class SeqOne_ < Struct.new(:first, :rest, :skipper, :idx)
    include Parser

    def _parse ctx
      ret = INVALID

      res = first._parse ctx
      return INVALID if INVALID[res]
      ret = res if 0 == idx

      check = idx - 1
      rest.each_with_index do |p, i|
        return INVALID if INVALID[skipper._parse ctx]
        res = p._parse ctx
        return INVALID if INVALID[res]
        ret = res if i == check
      end
      ret
    end
  end

  # unbox result size
  # only work for seq and join and maybe'ed seq and join
  class Unbox < Unary
    def _parse ctx
      res = some._parse ctx
      return INVALID if INVALID[res]
      res.size == 1 ? res.first : res
    end
  end

  # inner
  # only work for seq
  class Inner < Unary
    def _parse ctx
      res = some._parse ctx
      return INVALID if INVALID[res]
      res.shift
      res.pop
      res
    end
  end

end
