# coding: utf-8
# ------------------------------------------------------------------------------
# Binary Combinators

module Rsec #:nodoc:
  # binary combinator base
  Binary = Struct.new :left, :right
  class Binary
    include ::Rsec
  end

  # transform parse result
  class Map < Binary
    def _parse ctx
      res = left()._parse ctx
      return INVALID if INVALID[res]
      right()[res]
    end
  end

  # set expect tokens for parsing error in ctx<br/>
  # if left failed, the error would be registered
  class Fail < Binary
    def _parse ctx
      res = left()._parse ctx
      ctx.on_fail right if INVALID[res]
      res
    end
  end

  # look ahead
  class LookAhead < Binary
    def _parse ctx
      res = left()._parse ctx
      pos = ctx.pos
      return INVALID if INVALID[right()._parse ctx]
      ctx.pos = pos
      res
    end
  end

  # negative look ahead
  class NegativeLookAhead < Binary
    def _parse ctx
      res = left()._parse ctx
      pos = ctx.pos
      if INVALID[right()._parse ctx]
        ctx.pos = pos
        res
      end
    end
  end

  # Join base
  class Join
    include Rsec

    def self.[] token, inter
      self.new token, inter
    end

    def initialize token, inter
      @token = token
      @inter = inter
    end

    def _parse ctx
      e = @token._parse ctx
      return INVALID if INVALID[e]
      node = []
      node.push e unless SKIP[e]
      loop do
        save_point = ctx.pos
        i = @inter._parse ctx
        if INVALID[i]
          ctx.pos = save_point
          break
        end

        t = @token._parse ctx
        if INVALID[t]
          ctx.pos = save_point
          break
        end

        break if save_point == ctx.pos # stop if no advance, prevent infinite loop
        node.push i unless SKIP[i]
        node.push t unless SKIP[t]
      end # loop
      node
    end
  end

  # repeat from range.begin.abs to range.end.abs <br/>
  # note: range's max should always be > 0<br/>
  #       see also helpers
  class RepeatRange
    include Rsec

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
        rp_node.push res unless SKIP[res]
      end
      @optional.times do
        res = @base._parse ctx
        break if INVALID[res]
        rp_node.push res unless SKIP[res]
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
      @n = n.abs
    end
  end

  # matches exactly n.abs times repeat<br/>
  class RepeatN < RepeatXN
    def _parse ctx
      @n.times.inject([]) do |rp_node|
        res = @base._parse ctx
        return INVALID if INVALID[res]
        rp_node.push res unless SKIP[res]
      end
    end
  end

  # repeat at least n.abs times <- [n, inf) <br/>
  class RepeatAtLeastN < RepeatXN
    def _parse ctx
      rp_node = []
      @n.times do
        res = @base._parse(ctx)
        return INVALID if INVALID[res]
        rp_node.push res unless SKIP[res]
      end
      # note this may be an infinite action
      # returns if the pos didn't change
      loop do
        save_point = ctx.pos
        res = @base._parse ctx
        break if save_point == ctx.pos
        rp_node.push res unless SKIP[res]
      end
      rp_node
    end
  end

  class Wrap < Binary
    def _parse ctx
      return INVALID unless right[0] == ctx.getch
      res = left._parse ctx
      return INVALID if INVALID[res]
      return INVALID unless right[1] == ctx.getch
      res
    end
  end

  class SpacedWrap < Binary
    def _parse ctx
      return INVALID unless right[0] == ctx.getch
      ctx.skip /\s*/
      res = left._parse ctx
      return INVALID if INVALID[res]
      ctx.skip /\s*/
      return INVALID unless right[1] == ctx.getch
      res
    end
  end

  # primitive base
  module Prim
    def sign_strategy_to_pattern sign_strategy
      case sign_strategy
      when 3; '[\+\-]?'
      when 2; '\+?'
      when 1; '\-?'
      when 0; ''
      end
    end
  end

  # double precision float parser
  class PDouble < Binary
    include Prim

    def float_pattern sign_strategy, is_hex
      sign = sign_strategy_to_pattern sign_strategy
      if is_hex
        /#{sign}0x[\da-f]+(\.[\da-f]+)?/i
      else
        /#{sign}\d+(\.\d+)?(e[\+\-]?\d+)?/i
      end
    end

    def initialize sign_strategy, is_hex
      self.left = float_pattern sign_strategy, is_hex
    end

    def _parse ctx
      if (d = ctx.scan left)
        d = Float(d)
        return d if d.finite?
      end
      INVALID
    end
  end

  # primitive int parser commons
  class PInt < Binary
    include Prim

    def int_pattern sign_strategy, base
      sign = sign_strategy_to_pattern sign_strategy
      if base > 10
        d_hi = 9
        char_range = "a-#{('a'.ord + base - 11).chr}"
      else
        d_hi = base - 1
        char_range = ''
      end
      /#{sign}[0-#{d_hi}#{char_range}]+/i
    end

    def _parse ctx
      if (d = ctx.scan left)
        d = d.to_i @base
        return d if right.include?(d)
      end
      INVALID
    end
  end

  # 32-bit int parser
  class PInt32 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = (-(1<<31))..((1<<31)-1)
    end
  end

  # unsigned 32 bit int parser
  class PUnsignedInt32 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = 0...(1<<32)
    end
  end

  # 64-bit int parser
  class PInt64 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = (-(1<<63))..((1<<63)-1)
    end
  end

  # unsigned 64-bit int parser
  class PUnsignedInt64 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = 0...(1<<64)
    end
  end

end
