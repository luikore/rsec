$:.unshift '../lib'
$:.unshift '../ext'
require "rsec"
require "pp"

module FixPP
  def pretty_print(q)
    q.group(1, sprintf("<%s", self.class.name[/\w+$/]), '>') {
      q.seplist(self.members, ->{}) {|member|
        q.breakable
        q.text member.to_s
        q.text '='
        q.group(1) {
          q.breakable ''
          q.pp self[member]
        }
      }
    }
  end
end

class CMinus
  include Rsec::Helpers
  extend Rsec::Helpers

  # node decls
  
  class Function < Struct.new :type, :id, :params, :body
    include FixPP
  end

  class Expr < Struct.new :expr
    include FixPP
  end

  class Block < Struct.new :var_decls, :statements
    include FixPP
  end

  class Call < Struct.new :function, :args
    include FixPP
  end

  class GetIndex < Struct.new :id, :idx
    include FixPP
  end
  
  # "terminal" rules
  
  NUM       = prim :unsigned_int64
  INT       = prim :int64
  NBSP      = /[\ \t]*/.r
  SPACE     = /\s*/.r
  ID        = /[a-zA-Z]\w*/.r 'id'
  TYPE      = (word('int') | word('void')).fail 'type'
  EOSTMT    = ';'.r 'end of statement'
  ELSE      = word('else').fail 'keyword_else'
  IF        = word('if').fail 'keyword_if'
  WHILE     = word('while').fail 'keyword_while'
  RETURN    = word('return').fail 'keyword_return'
  MUL_OP    = symbol(/[\*\/%]/)
  ADD_OP    = symbol(/[\+\-]/)
  COMP_OP   = symbol(/(\<=|\<|\>|\>=|==|!=)/).fail 'compare operator'
  COMMA     = /\s*,\s*/.r 'comma'
  EMPTY_BRA = /\[\s*\]/.r 'empty square bracket'

  # call(function apply) expression
  def call expr
    args = expr.join(COMMA).even
    seq_(ID, '(', args._?, ')') {
      |(id, _, args, _)|
      Call[id, *args]
    }
  end

  # (binary) expression
  def expression
    binary_arithmetic = lazy{factor}
      .join(MUL_OP).unbox
      .join(ADD_OP).unbox
      .join(COMP_OP).unbox
    expr = lazy{assign} | binary_arithmetic
    # abc
    # abc[12]
    var = seq_(ID, seq_('[', expr, ']')[1]._?) {
      |(id, (index))|
      index ? GetIndex[id, index] : id
    }
    assign = seq_(var, '=', expr)
    factor = seq_('(', expr, ')')[1] | call(expr) | var | INT
    # p expr.parse! "gcd (v ,u- u/v *v)"
    expr.map{|e| Expr[e] }
  end
    
  # statement parser builder, returns [stmt, block]
  def statement var_decl
    expr = expression()
    brace = seq_('(', expr, ')')[1]
    # statement
    _stmt = lazy{stmt} # to reduce the use of lazy{}
    
    expr_stmt = seq_(expr, EOSTMT)[0] | EOSTMT
    else_stmt = seq_(ELSE, _stmt)[1]
    if_stmt = seq_(IF, brace, _stmt, else_stmt._?)
    while_stmt = seq_(WHILE, brace, _stmt)
    return_stmt = seq_(RETURN, expr._?, EOSTMT){
      |(ret, maybe_expr)|
      [ret, *maybe_expr]
    }
    # { var_decls statements }
    block = seq('{', SPACE.join(var_decl).odd, SPACE.join(_stmt).odd, '}'){
      |(_, vars, stats, _)|
      Block[vars, stats]
    }
    stmt = block | if_stmt | while_stmt | return_stmt | expr_stmt
    # p if_stmt.parse! 'if(v == 0)return u;'
    [stmt, block]
  end
  
  def initialize
    type_id = seq_(TYPE, ID).cached
    # p type_id.parse! 'int a'
    
    var_decl = seq_(type_id, seq_('[', NUM, ']')[1]._?, EOSTMT){
      |(id, maybe_num)|
      [id, *maybe_num]
    }
    # p var_decl.parse! 'int a[12];'
    # p var_decl.parse! 'int a;'

    stmt, block = statement(var_decl)
    # p block.parse! "{int a;}"
    # p stmt.parse! 'if(3==2) {return 4;}'
    
    param = seq_(type_id, EMPTY_BRA._?) {
      |((ty, id), maybe_bra)|
      [ty, id, *maybe_bra]
    }
    params = param.join(COMMA).even | 'void'.r{[]}
    brace = seq_('(', params, ')')[1]
    fun_decl = seq_(type_id, brace, block){
      |(type, id), params, block|
      Function[type, id, params, block]
    }
    # p fun_decl.parse! 'int gcd(int u, int v){return 2;}'
    @program = SPACE.join(fun_decl | var_decl | EOSTMT).odd.eof
  end
  
  attr_reader :program
end

if __FILE__ == $PROGRAM_NAME
  c_minus = CMinus.new
  nodes = c_minus.program.parse! %Q[
    int gcd(int u, int v)
    {
      if (v == 0) return u;
      else return gcd(v,u-u / v*v);
    }

    void main(void)
    {
      int x; int y;
      while (1) {
        x = input();
        y = input();
        output(gcd(x ,y)) ;
      }
    }
  ]
  nodes.each do |node|
    pp node
  end
end

