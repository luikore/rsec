# s-expression parser

require "rsec"

include Rsec::Helpers

def s_exp
  id    = /[a-zA-Z][\w\-]*/.r
  num   = /[\+\-]?\d+(\.\d+)?/.r.map(&:to_f)
  space = /\s+/.r.skip

  exp   = nil
  thing = id | num
  paren = (lazy{exp} | thing).wrap_('()') | thing
  exp   = [id, space, paren.join(space)._?].r.map{|n| n.flatten 1}
  exp.wrap_('()').eof
end

