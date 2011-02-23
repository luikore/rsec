# s-expression parser

require "rsec"

include Rsec::Helpers

def s_exp
  id    = /[a-zA-Z][\w\-]*/.r.fail 'id'
  num   = prim(:double).fail 'num'

  naked_unit = id | num | seq_('(', lazy{exp}, ')')[1]
  unit  = naked_unit | seq_('(', lazy{unit}, ')')[1]
  units = unit.join(/\s+/).even._?
  exp   = seq_(id, units) {|(id, (units))| [id, *units]}
  seq_('(', exp, ')')[1].eof
end

