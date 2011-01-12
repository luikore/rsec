# arithmetic implemented with operator table

require "rsec"

include Rsec::Helpers

def arithmetic_rpn
  # op[s] is a parser, it parses s and returns s.to_proc
  op = proc {|s|
    s.to_s.r >> value(s.to_proc)
  }

  num  = prim :double
  term = num | lazy{expr}.wrap_('()')
  # build operator table
  expr = term.join_infix_operators(
    calculate: true,
    left: {
      op[:+] => 5,
      op[:-] => 5,
      op[:**] => 15,
      op[:*] => 10,
      op[:/] => 10,
      op[:%] => 10
    }
  )

  expr.eof
end

