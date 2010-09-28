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

  class FallLeft < Binary
    def _parse ctx
      ret = left()._parse ctx
      return unless ret
      right()._parse ctx
      ret
    end
  end

  class FallRight < Binary
    def _parse ctx
      return unless left()._parse ctx
      right()._parse ctx
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
      return unless e
      node = []
      node.push e if e != :_skip_
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
        node.push i if i != :_skip_
        node.push t if t != :_skip_
      end # loop
      node
    end
  end

  # join inter, space
  class SpacedJoin < Join
    attr_accessor :space

    def _parse ctx
      e = @token._parse ctx
      return unless e
      node = []
      node.push e if e != :_skip_
      loop do
        save_point = ctx.pos

        break unless ctx.skip @space
        i = @inter._parse ctx
        unless i
          ctx.pos = save_point
          break
        end

        break unless ctx.skip @space
        ctx.skip @space
        t = @token._parse ctx
        unless t
          ctx.pos = save_point
          break
        end

        break if save_point == ctx.pos # stop if no advance, prevent infinite loop
        node.push i if i != :_skip_
        node.push t if t != :_skip_
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
        return nil unless res
        rp_node.push res if res != :_skip_
      end
      @optional.times do
        res = @base._parse ctx
        break unless res
        rp_node.push res if res != :_skip_
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
        return unless res
        rp_node.push res if res != :_skip_
      end
    end
  end

  # repeat at least n.abs times <- [n, inf) <br/>
  class RepeatAtLeastN < RepeatXN
    def _parse ctx
      rp_node = []
      @n.times do
        res = @base._parse(ctx)
        return unless res
        rp_node.push res if res != :_skip_
      end
      # note this may be an infinite action
      # returns if the pos didn't change
      loop do
        save_point = ctx.pos
        res = @base._parse ctx
        break if save_point == ctx.pos
        rp_node.push res if res != :_skip_
      end
      rp_node
    end
  end

  # infix operator table
  class ShuntingYard
    include ::Rsec

    # unify operator table
    def unify opt, is_left
      (opt || {}).inject({}) do |h, (k, v)|
        k = Rsec.make_parser k
        h[k] = [v.to_i, is_left]
        h
      end
    end

    def initialize term, opts
      @term = term
      @ops = unify(opts[:right], false)
      @ops.merge! unify(opts[:left], true)

      @space_before = opts[:space_before] || opts[:space] || /[\ \t]*/
      @space_after = opts[:space_after] || opts[:space] || /\s*/
      if @space_before.is_a?(String)
        @space_before = /#{Regexp.escape @space_before}/
      end
      if @space_after.is_a?(String)
        @space_after = /#{Regexp.escape @space_after}/
      end

      @ret_class = opts[:calculate] ? Pushy : Array
    end

    # TODO give it a better name
    class Pushy < Array
      # calculates on <<
      def << op
        right = pop()
        left = pop()
        push op[left, right]
      end
      # get first element
      def to_a
        raise 'fuck' if size != 1
        first
      end
    end

    # scan an operator from ctx
    def scan_op ctx
      save_point = ctx.pos
      @ops.each do |parser, (precedent, is_left)|
        ret = parser._parse ctx
        if ret
          return ret, precedent, is_left
        else
          ctx.pos = save_point
        end
      end
      nil
    end
    private :scan_op

    def _parse ctx
      stack = []
      ret = @ret_class.new
      token = @term._parse ctx
      return unless token
      ret.push token
      loop do
        save_point = ctx.pos

        # parse operator
        ctx.skip @space_before
        # operator-1, precedent-1, is-left-associative
        op1, pre1, is_left = scan_op ctx
        break unless op1 # pos restored in scan_op
        while top = stack.last
          op2, pre2 = top
          if (is_left and pre1 <= pre2) or (pre1 < pre2)
            stack.pop
            ret << op2 # tricky: Pushy calculates when <<
          else
            break
          end
        end
        stack.push [op1, pre1]
        
        # parse term
        ctx.skip @space_after
        token = @term._parse ctx
        unless token
          ctx.pos = save_point
          break
        end
        ret.push token
      end # loop

      while top = stack.pop
        ret << top[0]
      end
      ret.to_a # tricky: Pushy get the first thing out
    end
  end
end
