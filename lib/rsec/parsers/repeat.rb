module Rsec

  # the content appears 1 or 0 time
  class Maybe < Unary
    def _parse ctx
      save = ctx.pos
      res = some._parse ctx
      if INVALID[res]
        ctx.pos = save
        []
      else
        [res]
      end
    end
  end

  # repeat from range.begin.abs to range.end.abs <br/>
  # note: range's max should always be > 0<br/>
  #       see also helpers
  class RepeatRange
    include Parser

    def self.[] base, range
      self.new base, range
    end

    def initialize base, range
      @base = base
      @at_least = range.min.abs
      @optional = range.max - @at_least
    end

    def _parse ctx
      rp_node = []
      @at_least.times do
        res = @base._parse ctx
        return INVALID if INVALID[res]
        rp_node.push res
      end
      @optional.times do
        save = ctx.pos
        res = @base._parse ctx
        if INVALID[res]
          ctx.pos = save
          break
        end
        rp_node.push res
      end
      rp_node
    end
  end

  # matches exactly n.abs times repeat<br/>
  class RepeatN < Struct.new(:base, :n)
    include Parser
    def _parse ctx
      n.times.inject([]) do |rp_node|
        res = base._parse ctx
        return INVALID if INVALID[res]
        rp_node.push res
      end
    end
  end

  # repeat at least n.abs times <- [n, inf) <br/>
  class RepeatAtLeastN < Struct.new(:base, :n)
    include Parser
    def _parse ctx
      rp_node = []
      n.times do
        res = base._parse(ctx)
        return INVALID if INVALID[res]
        rp_node.push res
      end
      # note this may be an infinite action
      # returns if the pos didn't change
      loop do
        save = ctx.pos
        res = base._parse ctx
        if (INVALID[res] or ctx.pos == save)
          ctx.pos = save
          break
        end
        rp_node.push res
      end
      rp_node
    end
  end

end
