require "rsec"

class CMinus
  include Rsec::Helpers
  
  # "terminal" rules
  ID     = /[a-zA-Z]\w*/.r
  NUM    = /\d+/.r
  INT    = /[+-]?\d+/.r
  NBSP   = /[\ \t]*/.r.skip
  SPACE  = /\s*/.r.skip
  TYPE   = /int|void/.r
  EOSTMT = /;/.r.skip # end of statement
  
  # ------------------- helpers
  
  def seq *xs
    xs.r(skip: /\s*/)
  end

  # call(function apply) expression
  def call expr
    args = expr.join /\s*,\s*/.r.skip
    [ID, SPACE, args._?.wrap_('()')].r
  end

  # binary arithmetic
  def binary_arithmetic factor
    factor.join_infix_operators \
      space: /\s*/,
      left: {
        /\<=|\<|\>|\>=|==|!=/ => 5,
        /[\+\-]/ => 10,
        /[\*\/%]/ => 20
      }
  end
  
  # (binary) expression
  def expression
    _expr = lazy{expr}
    
    var = [ID, SPACE, _expr.wrap_('[]')._?].r
    factor = _expr.wrap_('()') | call(_expr) | var | INT
    expr = seq(var, '=', _expr) | binary_arithmetic(factor)
    # p expr.parse! "gcd(v,u-u/v*v)"
    expr
  end
    
  # statement parser builder, returns [stmt, block]
  def statement var_decl
    expr = expression()
    brace = expr.wrap_('()')
    # statement
    _stmt = lazy{stmt} # to reduce the use of lazy{}
    
    expr_stmt = expr << EOSTMT | EOSTMT
    else_stmt = [/else\s+/, _stmt].r
    if_stmt = seq('if', brace, _stmt, else_stmt._?)
    while_stmt = seq('while', brace, _stmt)
    return_stmt = [/return\s+/, expr._?].r << EOSTMT
    block = [SPACE.join(var_decl), SPACE.join(_stmt)].r.wrap_ '{}'
    stmt = block | if_stmt | while_stmt | return_stmt | expr_stmt
    [stmt, block]
  end
  
  def initialize
    type_id = [TYPE << /[\ \t]+/, ID].r.cached
    # p type_id.parse! 'int a'
    
    var_decl = seq(type_id, NUM.wrap_('[]')._?) << EOSTMT
    # p var_decl.parse! 'int a[12];'
    # p var_decl.parse! 'int a;'

    stmt, block = statement(var_decl)
    # p block.parse! "{int a;}"
    # p stmt.parse! 'gcd(v,u-u/v*v);'
    
    param = seq(type_id, /\[\s*\]/.r._?)
    params = param.join(/\s*,\s*/.r.skip) | 'void'
    brace = params.wrap_ '()'
    fun_decl = seq(type_id, brace, block)
    @program = SPACE.join(fun_decl | var_decl).eof
  end
  
  attr_reader :program
end

c_minus = CMinus.new
require "pp"

pp c_minus.program.parse! %Q[
int gcd(int u, int v)
{
  if (v == 0) return u ;
  else return gcd(v,u-u/v*v);
}

void main(void)
{
  int x; int y;
  x = input();
  y = input();
  output(gcd(x ,y)) ;
}
]
