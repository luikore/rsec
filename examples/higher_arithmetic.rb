# higer arithmetic parser ('**' included)

require "rsec"

include Rsec::Helpers

def higher_arithmetic
  calculate = proc do |(p, *ps)|
    ps.each_slice(2).inject(p) do |left, (op, right)|
      left.send op.strip, right
    end
  end

  float  = /[\+\-]?\d+(?:\.\d+)?/.r.map(&:to_f)
  bra    = /\(\s*/.r.skip
  ket    = /\s*\)/.r.skip
  expr   = nil # declare for lazy
  paren  = (bra < lazy{expr} < ket)[1]

  term4  = float | paren
  term3  = term4.join(/\s*\*\*\s*/).map &calculate
  term2  = term3.join(/\s*[\*\/\%]\s*/).map &calculate
  term1  = term2.join(/\s*[\+\-]\s*/).map &calculate
  expr   = term1
  expr.eof
end

