# s-expression parser

require "rsec"

include Rsec::Helpers

def s_exp
  id    = /[a-zA-Z][\w\-]*/.r
  num   = /[\+\-]?\d+(\.\d+)?/.r.map &:to_f
  thing = id | num
  space = /\s+/.r.skip
  bra   = /\(\s*/.r
  ket   = /\s*\)/.r

  exp   = nil
  paren = (bra < (lazy{exp} | thing) < ket)[1] | thing
  exp   = (id < space < paren.join(space)._?).map{|n| n.flatten 1}
  (bra < exp < ket)[1].eof
end

