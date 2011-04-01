# A simple-as-shit scheme interpreter. Usage: ruby scheme.rb hello.scm
require "rsec"

class Scheme
  include Rsec::Helpers

  Value = Struct.new :val

  class Bind < Hash
    def initialize parent = {}
      @parent = parent
    end

    def define id, &p # define lambda
      self[id] = -> bind, xs {
        p[* xs.map{|x| bind.eval x }]
      }
    end

    def eval node
      case node
      when Value;  node.val
      when String; self[node]
      when Array
        head, *tail = node
        case head
        when String
          pr = self[head]
          pr.is_a?(Proc) ? pr[self, tail] : pr # invoke lambda
        when Array
          node.map{|n| self.eval n }.last # sequence execution
        end
      end
    end

    def [] key
      super(key) || @parent[key]
    end
  end

  def initialize
    boolean = /\#[tf]/.    r {|n| Value[n=='#t'] }
    integer = /0|[1-9]\d*/.r {|n| Value[n.to_i]  }
    id      = /[^\s\(\)\[\]]+/.r
    atom    = boolean | integer | id
    cell    = atom | lazy{list}
    cells   = /\s*/.r.join(cell).odd
    list    = '('.r >> cells << ')'
    @parser = cells.eof

    @vm = Bind.new
    @vm['define'] = -> bind, (param, body) {
      if param.is_a?(String)
        @vm[param] = bind.eval body
      else
        func, *xs = param
        @vm[func] = @vm['lambda'][bind, [xs, body]]
      end
    }
    # declare: (lambda (xs[0] xs[1]) body)
    @vm['lambda'] = -> bind_def, (xs, body) {
      xs = [xs] if xs.is_a?(String)
      # calling: (some vs[0] vs[1])
      -> bind_call, vs {
        vs = vs.map{|v| bind_call.eval v }
        new_bind = Bind.new bind_def
        xs.zip(vs){|x, v| new_bind[x] = v }
        new_bind.eval body
      }
    }
    @vm['if'] = -> bind, (p, left, right) {
      bind.eval(bind.eval(p) ? left : right)
    }
    %w|+ - * / ** % > <|.each{|s| @vm.define s, &s.to_sym }
    @vm.define '=', &:==
    @vm.define('display'){|x| puts x}
  end

  def run source
    @vm.eval @parser.parse! source
  end
end

ARGV[0] ? Scheme.new.run(File.read ARGV[0]) : puts('need a scheme file name')
