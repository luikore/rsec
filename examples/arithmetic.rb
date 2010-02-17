# arithmetic parser

require "rsec"

include Rsec::Helpers

def arithmetic
  calculate = proc do |(p, *ps)|
    ps.each_slice(2).inject(p) do |left, (op, right)|
      left.send op.strip, right
    end
  end

  num    = /[+-]?[1-9]\d*(\.\d+)?/.r.map &:to_f
  bra    = '('.r.skip
  ket    = ')'.r.skip
  expr   = nil # declare for lazy
  paren  = (bra << lazy{expr} << ket).map &:first
  factor = paren | num
  term   = factor.join(/\s*[\*\/]\s*/).map &calculate
  expr  = term.join(/\s*[\+\-]\s*/).map &calculate
end
