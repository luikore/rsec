# arithmetic parser

require "rsec"

include Rsec::Helpers

def arithmetic
  calculate = proc do |(p, *ps)|
    ps.each_slice(2).inject(p) do |left, (op, right)|
      left.send op, right
    end
  end

  num    = /[+-]?[1-9]\d*(\.\d+)?/.r.map &:to_f
  expr   = nil # declare for lazy
  paren  = lazy{expr}.wrap_ '()'
  factor = num | paren
  term   = factor.join(one_of_('*/%')).map &calculate
  expr   = term.join(one_of_('+-')).map &calculate
  expr.eof
end
