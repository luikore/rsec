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

  # set the parsing error in ctx<br/>
  # if left failed, the error would show up<br/>
  # if not, the error disappears
  class Fail < Binary
    def _parse ctx
      ctx.err = right()
      res = left()._parse ctx
      ctx.err = nil unless INVALID[res]
      res
    end
  end

  class FallLeft < Binary
    def _parse ctx
      ret = left()._parse ctx
      return INVALID if INVALID[ret]
      return INVALID if INVALID[right()._parse ctx]
      ret
    end
  end

  class FallRight < Binary
    def _parse ctx
      return INVALID if INVALID[left()._parse ctx]
      right()._parse ctx
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

  # TODO the following parsers should be ajusted to more precised level
  # NOTE these classes are designed for C-ext, so the ruby code look a little wierd

  def Rsec.sign_strategy_to_pattern sign_strategy
    case sign_strategy
    when 3; '[\+\-]?'
    when 2; '\+?'
    when 1; '\-?'
    when 0; ''
    end
  end

  # double precision float parser
  class PDouble < Binary
    def initialize sign_strategy, is_hex
      super(sign_strategy, is_hex)
      sign = Rsec.sign_strategy_to_pattern sign_strategy
      @pattern =
        if is_hex
          /#{sign}0x[\da-f]+(\.[\da-f]+)?/i
        else
          /#{sign}\d+(\.\d+)?(e[\+\-]?\d+)?/i
        end
    end

    def _parse ctx
      if (d = ctx.scan @pattern)
        d = Float(d)
        return d if d.finite?
      end
      INVALID
    end
  end

  # single precision float parser
  class PFloat < Binary
    def initialize sign_strategy, is_hex
      super(sign_strategy, is_hex)
      sign = Rsec.sign_strategy_to_pattern sign_strategy
      @pattern =
        if is_hex
          /#{sign}0x[\da-f]+(\.[\da-f]+)?/i
        else
          /#{sign}\d+(\.\d+)?(e[\+\-]?\d+)?/i
        end
    end

    def _parse ctx
      if (d = ctx.scan @pattern)
        d = Float(d)
        return d if d.finite? # TODO single pecision float check
      end
      INVALID
    end
  end

  # 32-bit int parser
  class PInt32 < Binary
    def initialize sign_strategy, base
      super(sign_strategy, base)
      sign = Rsec.sign_strategy_to_pattern sign_strategy
      if base > 10
        d_hi = 9
        char_range = "a-#{('a'.ord + base - 11).chr}"
      else
        d_hi = base - 1
        char_range = ''
      end
      @pattern = /#{sign}[0-#{d_hi}#{char_range}]+/i
    end

    def _parse ctx
      if (d = ctx.scan @pattern)
        d = d.to_i right
        return d if (-2147483648..2147483647).include?(d)
      end
      INVALID
    end
  end

  # unsigned 32 bit int parser
  class PUnsignedInt32 < Binary
    def initialize sign_strategy, base
      super(sign_strategy, base)
      sign = Rsec.sign_strategy_to_pattern sign_strategy
      if base > 10
        d_hi = 9
        char_range = "a-#{('a'.ord + base - 11).chr}"
      else
        d_hi = base - 1
        char_range = ''
      end
      @pattern = /#{sign}[0-#{d_hi}#{char_range}]+/i
    end

    def _parse ctx
      if (d = ctx.scan @pattern)
        d = d.to_i right
        return d if d < 4294967296
      end
      INVALID
    end
  end

  # NOTE
  # VC has no strtoll and strtoull
  # class PInt64 < Binary; end
  # class PUnsignedInt64 < Binary; end

end
