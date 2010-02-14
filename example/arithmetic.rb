require "rubygems"
require "rsec"

def parser
  calculate = proc do |(p, *ps)|
    ps.each_slice(2).inject(p) do |left, (op, right)|
      left.send op.strip, right
    end
  end

  int    = /[\+\-]?\d+/.r.map &:to_i
  bra    = '('.r.skip
  ket    = ')'.r.skip
  paren  = (bra << lazy{@expr} << ket).map &:first
  factor = paren | int
  term   = factor.join(/\s*[\*\/]\s*/).map &calculate
  @expr  = term.join(/\s*[\+\-]\s*/).map &calculate
end

str = '1+2-3*4*5/((2*3)+6)-7'
print str, ' = '
puts parser.parse '1+2-3*4*5/((2*3)+6)-7' #=> -9
