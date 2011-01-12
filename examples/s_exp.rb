# s-expression parser

require "rsec"

include Rsec::Helpers

def s_exp
  id    = /[a-zA-Z][\w\-]*/.r
  num   = /[\+\-]?\d+(\.\d+)?/.r &:to_f
  space = /\s+/.r.skip

  thing = id | num
  paren = (lazy{exp} | thing).wrap_('()') | thing
  exp   = [id, space, paren.join(space)._?].r{|n| n.flatten 1}
  exp.wrap_('()').eof
end

