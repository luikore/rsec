module Rsec
  
  # Join base
  class Join < Binary
    def _parse ctx
      e = left._parse ctx
      return INVALID if INVALID[e]
      ret = [e]
      loop do
        save_point = ctx.pos
        i = right._parse ctx
        if INVALID[i]
          ctx.pos = save_point
          break
        end

        t = left._parse ctx
        if INVALID[t]
          ctx.pos = save_point
          break
        end

        break if save_point == ctx.pos # stop if no advance, prevent infinite loop
        ret << i
        ret << t
      end # loop
      ret
    end
  end

  # keep only tokens
  class JoinEven < Binary
    def _parse ctx
      e = left._parse ctx
      return INVALID if INVALID[e]
      ret = [e]
      loop do
        save_point = ctx.pos
        i = right._parse ctx
        if INVALID[i]
          ctx.pos = save_point
          break
        end

        t = left._parse ctx
        if INVALID[t]
          ctx.pos = save_point
          break
        end

        break if save_point == ctx.pos # stop if no advance, prevent infinite loop
        ret << t
      end # loop
      ret
    end
  end

  # keep only inters
  # NOTE if only 1 token matches, return empty array
  class JoinOdd < Binary
    def _parse ctx
      e = left._parse ctx
      return INVALID if INVALID[e]
      ret = []
      loop do
        save_point = ctx.pos
        i = right._parse ctx
        if INVALID[i]
          ctx.pos = save_point
          break
        end

        t = left._parse ctx
        if INVALID[t]
          ctx.pos = save_point
          break
        end

        break if save_point == ctx.pos # stop if no advance, prevent infinite loop
        ret << i
      end # loop
      ret
    end
  end

end
