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
        if INVALID[ret]
          ctx.pos = save_point
        else
          return ret, precedent, is_left
        end
      end
      nil
    end
    private :scan_op

    def _parse ctx
      stack = []
      ret = @ret_class.new
      token = @term._parse ctx
      return INVALID if INVALID[token]
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
        if INVALID[token]
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

  # infix operator table implemented with Shunting-Yard algorithm<br/>
  # call-seq:
  # <pre>
  #     /\w+/.r.join_infix_operators \
  #       space: ' ',
  #       left: {'+' => 30, '*' => 40},
  #       right: {'=' => 20}
  # </pre>
  # options:
  # <pre>
  #     space: sets space_before and space_after at the same time
  #     space_before: skip the space before operator
  #     space_after: skip the space after operator
  #     left: left associative operator table, in the form of "{operator => precedence}"
  #     right: right associative operator table
  # </pre>
  # NOTE: outputs reverse-polish-notation(RPN)<br/>
  # NOTE: should put "**" before "*"
  def join_infix_operators opts={}
    # TODO: also make AST output available?
    # TODO: now operator acceps string only, make it parser aware
    ShuntingYard.new self, opts
  end
