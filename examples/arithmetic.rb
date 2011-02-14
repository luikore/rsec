# arithmetic parser

require "rsec"

include Rsec::Helpers

def arithmetic
  calculate = proc do |(p, *ps)|
    ps.each_slice(2).inject(p) do |left, (op, right)|
      left.send op, right
    end
  end

  num    = prim :double
  paren  = lazy{expr}.wrap_ '()'
  factor = branch(num, paren)
  term   = factor.join(one_of_('*/%')).map &calculate
  expr   = term.join(one_of_('+-')).map &calculate
  expr.eof
end
