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
  bra    = /\(\s*/.r.skip
  ket    = /\s*\)/.r.skip
  expr   = nil # declare for lazy
  paren  = bra >> lazy{expr} << ket
  factor = num | paren
  term   = factor.join(/[\*\/]/, /\s*/).map &calculate
  expr   = term.join(/[\+\-]/, /\s*/).map &calculate
  expr.eof
end
