# s-expression parser

require "rsec"

include Rsec::Helpers

def s_exp
  id    = /[a-zA-Z][\w\-]*/.r
  num   = prim(:double)
  space = /\s+/.r.skip

  thing = branch(id, num)
  paren = branch(lazy{exp}, thing).wrap_ '()'
  term  = branch paren, thing
  exp   = seq(id, space, term.join(space)._?){|arr| arr.flatten 1}
  exp.wrap_('()').eof
end

