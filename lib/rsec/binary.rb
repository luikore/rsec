# coding: utf-8
# ------------------------------------------------------------------------------
# Binary Combinators

module Rsec
  # binary combinator base
  Binary = Struct.new :left, :right
  class Binary
    include ::Rsec
  end

  # transform parse result
  class Map < Binary
    def _parse ctx
      if res = left()._parse(ctx)
        right()[res]
      end
    end
  end

  # called on parsing result
  class On < Binary
    def _parse ctx
      if res = left()._parse(ctx)
        right()[res]
        res
      end
    end
  end

  # set the parsing error in ctx<br/>
  # if left failed, the error would show up<br/>
  # if not, the error disappears
  class Fail < Binary
    def _parse ctx
      ctx.err = right()
      res = left()._parse ctx
      ctx.err = nil if res
      res
    end
  end

  # look ahead
  class LookAhead < Binary
    def _parse ctx
      res = left()._parse ctx
      pos = ctx.pos
      if right()._parse(ctx)
        ctx.pos = pos
        res
      end
    end
  end

  # negative look ahead
  class NegativeLookAhead < Binary
    def _parse ctx
      res = left()._parse ctx
      pos = ctx.pos
      if ! right()._parse(ctx)
        ctx.pos = pos
        res
      end
    end
  end

  # Ljoin and Rjoin base
  class Xjoin
    include Rsec

    def self.[] token, inter
      self.new token, inter
    end

    def initialize token, inter
      @token = token
      @inter = inter
      # tricky: determine node class and default return with reflection
      @node_class = \
        if is_a?(Ljoin) or is_a?(Ljoin_)
          LAssocNode
        else
          RAssocNode
        end
      # note the underlines
      @default_ret = \
        if is_a?(Ljoin_)
          LAssocNode[]
        elsif is_a?(Rjoin_)
          RAssocNode[]
        end
    end

    def _parse ctx
      e = @token._parse ctx
      return @default_ret unless e
      node = @node_class[e]
      loop do
        save_point = ctx.pos
        i = @inter._parse ctx
        unless i
          ctx.pos = save_point
          break
        end

        t = @token._parse ctx
        unless t
          ctx.pos = save_point
          break
        end

        break if save_point == ctx.pos # stop if no advance, prevent infinite loop
        node.assoc i
        node.assoc t
      end # loop
      node
    end
  end

  # token joined by inter<br/>
  # result is left associative
  class Ljoin < Xjoin; end

  # token joined by inter<br/>
  # result is right associative
  class Rjoin < Xjoin; end

  class Ljoin_ < Xjoin; end
  class Rjoin_ < Xjoin; end

  # repeat from range.begin.abs to range.end.abs <br/>
  # if the range starts with a negative number, then result is right associative<br/>
  # note: range's max should always be > 0<br/>
  #       see also helpers
  class RepeatRange
    include Rsec

    def self.[] base, range
      self.new base, range
    end

    def initialize base, range
      @base = base
      @node_class = range.begin > 0 ? LAssocNode : RAssocNode
      @at_least = range.min.abs
      @optional = range.max - @at_least
    end

    def _parse ctx
      rp_node = @node_class.new
      @at_least.times do
        res = @base._parse ctx
        return nil unless res
        rp_node.assoc res
      end
      @optional.times do
        res = @base._parse ctx
        break unless res
        rp_node.assoc res
      end
      rp_node
    end
  end

  # base for RepeatN and RepeatAtLeastN
  class RepeatXN
    include Rsec

    def self.[] base, n
      self.new base, n
    end

    def initialize base, n
      raise "type mismatch, <#{n}> should be a Fixnum" unless n.is_a? Fixnum
      @base = base
      @node_class = n > 0 ? LAssocNode : RAssocNode
      @n = n.abs
    end
  end

  # matches exactly n.abs times repeat<br/>
  # if n < 0, result is right associative
  class RepeatN < RepeatXN
    def _parse ctx
      @n.times.inject(@node_class.new) do |rp_node|
        res = @base._parse ctx
        return nil unless res
        rp_node.assoc res
      end
    end
  end

  # repeat at least n.abs times <- [n, inf) <br/>
  # if n < 0, result is right associative
  class RepeatAtLeastN < RepeatXN
    def _parse ctx
      rp_node = @node_class.new
      @n.times do
        res = @base._parse(ctx)
        return nil unless res
        rp_node.assoc res
      end
      # note this may be an infinite action
      # returns if the pos didn't change
      loop do
        save_point = ctx.pos
        res = @base._parse ctx
        break if save_point == ctx.pos
        rp_node.assoc res
      end
      rp_node
    end
  end
end
