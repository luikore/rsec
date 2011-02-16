$:.unshift '../lib'
module Rsec; USE_CEXT = :no; end
require "rsec"

class CMinus
  include Rsec::Helpers
  
  # "terminal" rules
  ID        = /[a-zA-Z]\w*/.r :id
  NUM       = /\d+/.r :num
  INT       = /[+-]?\d+/.r :int
  NBSP      = /[\ \t]*/.r.skip
  SPACE     = /\s*/.r.skip
  TYPE      = /int|void/.r :type
  EOSTMT    = /;/.r(';').skip # end of statement
  ELSE      = /else\s/.r :keyword_else
  IF        = 'if'.r :keyword_if
  WHILE     = 'while'.r :keyword_while
  RETURN    = /return\s/.r :keyword_return
  MUL_OP    = /\s*[\*\/%]\s*/.r '*/%', &:strip
  ADD_OP    = /\s*[\+\-]\s*/.r '+-', &:strip
  COMP_OP   = /\s*(\<=|\<|\>|\>=|==|!=)\s*/.r 'compare operator', &:strip
  COMMA     = /\s*,\s*/.r(:comma).skip
  EMPTY_BRA = /\[\s*\]/.r('empty square bracket')

  # ------------------- helpers
  
  # call(function apply) expression
  def call expr
    args = expr.join /\s*,\s*/.r.skip
    seq_(ID, SPACE, args._?.wrap_('()'))
  end

  # (binary) expression
  def expression
    binary_arithmetic = lazy{factor}
      .join(MUL_OP).flatten
      .join(ADD_OP).flatten
      .join(COMP_OP).flatten
    expr = lazy{assign} | binary_arithmetic
    # abc
    # abc[12]
    var = seq_(ID, expr.wrap_('[]')._?).flatten
    assign = seq_(var, '=', expr)
    factor = expr.wrap_('()') | call(expr) | var | INT
    # p expr.parse! "gcd (v ,u- u/v *v)"
    expr
  end
    
  # statement parser builder, returns [stmt, block]
  def statement var_decl
    expr = expression()
    brace = expr.wrap_('()')
    # statement
    _stmt = lazy{stmt} # to reduce the use of lazy{}
    
    expr_stmt = seq_(expr, EOSTMT).flatten | EOSTMT
    else_stmt = seq_(ELSE, _stmt)
    if_stmt = seq_(IF, brace, _stmt, else_stmt._?)
    while_stmt = seq_(WHILE, brace, _stmt)
    return_stmt = seq_(RETURN, expr._?, EOSTMT)
    # { var_decls statements }
    block = seq_(SPACE.join(var_decl), SPACE.join(_stmt)).wrap_ '{}'
    stmt = block | if_stmt | while_stmt | return_stmt | expr_stmt
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
    
    param = seq_(type_id, EMPTY_BRA._?)
    params = param.join(COMMA) | 'void'
    brace = params.wrap_ '()'
    fun_decl = seq_(type_id, brace, block)
    # p fun_decl.parse! 'int gcd(int u, int v){return 2;}'
    @program = SPACE.join(fun_decl | var_decl | EOSTMT).eof
  end
  
  attr_reader :program
end

c_minus = CMinus.new
require "pp"

pp c_minus.program.parse! %Q[
int gcd(int u, int v)
{
  if (v == 0) return u x;
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
