# A simple scheme interpreter
require "rsec"

class Scheme
  include Rsec::Helpers

  def initialize
    spacee  = /\s*/.r.skip
    boolean = /\#[tf]/.    r.map {|n| ValueNode[n=='#t'] }
    integer = /0|[1-9]\d*/.r.map {|n| ValueNode[n.to_i]  }
    id      = /[^\s\(\)\[\]]+/.r.map {|n|
                def n.eval bind, *xs
                  bind[self]
                end
                n
              }
    atom    = boolean | integer | id
    list    = nil # declare for lazy
    cell    = atom | lazy{list}
    list    = spacee.join(cell).wrap('()').map {|n| ListNode[*n] }
    cells   = spacee.join(cell).map {|n| ListNode[*n] }
    @parser = cells.eof
  end

  def run source
    res = @parser.parse! source
    res.eval Runtime.new
  end
  
  ValueNode = Struct.new :val
  class ValueNode
    def eval *xs; val; end
    def pretty_print q; q.text "<#{val}>"; end
  end
  
  class ListNode < Array
    def eval bind
      head, *tail = self
      case head
      when String
        pr = bind[head]
        pr.is_a?(Proc) ? pr[bind, tail] : pr
      when ListNode
        map{|n| n.eval bind }.last
      end
    end
  end
  
  class Bind < Hash
    def initialize parent = {}
      @parent = parent
    end
    def [] key
      super(key) || @parent[key]
    end
    def define id, &p
      self[id] = proc do |bind, xs|
        p[* xs.map{|x| x.eval bind }]
      end
    end
  end

  class Runtime < Bind
    def initialize
      super()
      
      self['define'] = proc do |bind, (param, body)|
        case param
        when ListNode
          func, *xs = param
          self[func] = self['lambda'][bind, [xs, body]]
        when String
          self[param] = body.eval bind
        end
      end
      
      # declare: (lambda (xs[0] xs[1]) body)
      self['lambda'] = proc do |bind_def, (xs, body)|
        xs = [xs] if xs.is_a?(String)
        new_bind = Bind.new bind_def
        # calling: (some vs[0] vs[1])
        proc do |bind_call, vs|
          vs = vs.map{|v| v.eval bind_call}
          body.eval new_bind.merge(Hash[xs.zip vs])
        end
      end
      
      self['if'] = proc do |bind, (p, left, right)|
        p.eval(bind) ? left.eval(bind) : right.eval(bind)
      end
      
      %w|+ - * / ** % > <|.each{|s| define s, &s.to_sym }
      define '=', &:==
      define('display'){|x| puts x}
    end
  end
end

Scheme.new.run File.read ARGV[0]
