# coding: utf-8
# ------------------------------------------------------------------------------
# x-nary combinators

module Rsec

  # sequence combinator<br/>
  # result in an array
  class Seq < Array
    include ::Rsec

    def _parse ctx
      ret = []
      each do |e|
        res = e._parse ctx
        return INVALID if INVALID[res]
        ret << res unless SKIP[res]
      end
      ret
    end

    def [] idx
      raise 'index out of range' if idx >= size() or idx < 0
      s1 = SeqOne[*self]
      s1.idx = idx
      s1
    end
  end

  # skips a parser(@inner_skip) between tokens
  class SeqInnerSkip < Array
    include ::Rsec
    attr_accessor :inner_skip

    def _parse ctx
      ret = []
      skipper = nil
      each do |e|
        # no skip first token
        if skipper
          return INVALID if INVALID[skipper._parse ctx]
        end
        res = e._parse ctx
        return INVALID if INVALID[res]
        ret << res unless SKIP[res]
        skipper = @inner_skip
      end
      ret
    end

    def [] idx
      raise 'index out of range' if idx >= size() or idx < 0
      s1 = SeqOneInnerSkip[*self]
      s1.idx = idx
      s1.inner_skip = @inner_skip if @inner_skip
      s1
    end
  end
  
  # sequence combinator<br/>
  # the result is the result of the parser at idx
  class SeqOne < Array
    include ::Rsec
    attr_accessor :idx

    def _parse ctx
      ret = INVALID
      counter = 0
      each do |p|
        res = p._parse ctx
        return INVALID if INVALID[res]
        if INVALID[ret]
          ret = res if counter == @idx and ! SKIP[res]
        end
        counter += 1 unless SKIP[res]
      end
      ret
    end
  end

  class SeqOneInnerSkip < Array
    include ::Rsec
    attr_accessor :inner_skip, :idx

    def _parse ctx
      ret = INVALID
      counter = 0
      skipper = nil
      each do |p|
        # no skip first token
        if skipper
          return INVALID if INVALID[skipper._parse ctx]
        end
        res = p._parse ctx
        return INVALID if INVALID[res]
        if INVALID[ret]
          ret = res if counter == @idx and ! SKIP[res]
        end
        counter += 1 unless SKIP[res]
        skipper = @inner_skip
      end
      ret
    end
  end

  # or combinator<br/>
  # result in on of the members, or nil
  class Or < Array
    include ::Rsec

    def _parse ctx
      save_point = ctx.pos
      each do |e|
        res = e._parse ctx
        return res unless INVALID[res]
        ctx.pos = save_point
      end
      INVALID # don't forget to fail it when none of the elements matches
    end
  end # class
end
