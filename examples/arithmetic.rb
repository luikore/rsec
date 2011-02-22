# arithmetic parser

require "rsec"

include Rsec::Helpers

def arithmetic
  calculate = proc do |(p, *ps)|
    ps.each_slice(2).inject(p) do |left, (op, right)|
      left.send op, right
    end
  end

  num    = prim(:double).fail 'number'
  paren  = seq_('(', lazy{expr}, ')')[1]
  factor = num | paren
  term   = factor.join(one_of_('*/%').fail 'operator').map &calculate
  expr   = term.join(one_of_('+-').fail 'operator').map &calculate
  expr.eof
end

if __FILE__ == $PROGRAM_NAME
  p one_of_('+-').class
end

