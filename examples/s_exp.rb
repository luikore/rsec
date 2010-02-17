# s-expression parser

require "rsec"

include Rsec::Helpers

def s_exp
  id = /[a-zA-Z][\w\-]*/.r
  num = /[\+\-]?\d+(\.\d+)?/.r.map &:to_f
  thing = id | num

  bra = '('.r.skip
  ket = ')'.r.skip
  exp = nil
  paren =  (bra << (lazy{exp} | thing) << ket).map(&:first) | thing

  exp = (   id < space < paren.join(space)._?   ).map{|n| n.flatten 1}
  (bra << exp << ket).map(&:first)
end

