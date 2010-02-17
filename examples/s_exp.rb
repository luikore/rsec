require "rsec"
include Rsec::Helpers

def s_exp
  id = /[a-zA-Z][\w\-]*/.r
  num = float.map &:to_f
  thing = id | num

  bra = '('.r.skip
  ket = ')'.r.skip
  paren =  (bra << (lazy{@exp} | thing) << ket).map(&:first) | thing

  @exp = (   id < space < paren.join(space)._?   ).map{|n| n.flatten 1}
  (bra << @exp << ket).map(&:first)
end

