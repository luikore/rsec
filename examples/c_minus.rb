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
  
  # call(function apply) expression
  def call expr
    args = expr.join /\s*,\s*/.r.skip
    seq_(ID, SPACE, args._?.wrap_('()'))
  end

  # binary arithmetic
  def binary_arithmetic factor
    factor.join(/\s*[\*\/%]\s*/.r &:strip).flatten
          .join(/\s*[\+\-]\s*/.r &:strip).flatten
          .join(/\s*(\<=|\<|\>|\>=|==|!=)\s*/.r &:strip).flatten
  end
  
  # (binary) expression
  def expression
    expr = branch(lazy{assign}, binary_arithmetic(lazy{factor}))
    # abc
    # abc[12]
    var = seq_(ID, expr.wrap_('[]')._?).flatten
    assign = seq_(var, '=', expr)
    factor = branch(expr.wrap_('()'), call(expr), var, INT)
    # p expr.parse! "gcd (v ,u- u/v *v)"
    expr
  end
    
  # statement parser builder, returns [stmt, block]
  def statement var_decl
    expr = expression()
    brace = expr.wrap_('()')
    # statement
    _stmt = lazy{stmt} # to reduce the use of lazy{}
    
    expr_stmt = branch(seq_(expr, EOSTMT).flatten, EOSTMT)
    else_stmt = seq_(/else\s/, _stmt)
    if_stmt = seq_('if', brace, _stmt, else_stmt._?)
    while_stmt = seq_('while', brace, _stmt)
    return_stmt = seq_(/return\s/, expr._?, EOSTMT)
    # { var_decls statements }
    block = seq_(SPACE.join(var_decl), SPACE.join(_stmt)).wrap_ '{}'
    stmt = branch(block, if_stmt, while_stmt, return_stmt, expr_stmt)
    # p if_stmt.parse! 'if(v == 0)return u;'
    [stmt, block]
  end
  
  def initialize
    type_id = seq_(TYPE, ID).cached
    # p type_id.parse! 'int a'
    
    var_decl = seq_(type_id, NUM.wrap_('[]')._?, EOSTMT).flatten
    # p var_decl.parse! 'int a[12];'
    # p var_decl.parse! 'int a;'

    stmt, block = statement(var_decl)
    # p block.parse! "{int a;}"
    # p stmt.parse! 'gcd(v,u-u/v*v);'
    # p stmt.parse! 'if(3==2) {return 4;}'
    
    param = seq_(type_id, /\[\s*\]/.r._?)
    params = branch(param.join(/\s*,\s*/.r.skip), 'void')
    brace = params.wrap_ '()'
    fun_decl = seq_(type_id, brace, block)
    # p fun_decl.parse! 'int gcd(int u, int v){return 2;}'
    @program = SPACE.join(branch fun_decl, var_decl, EOSTMT).eof
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
