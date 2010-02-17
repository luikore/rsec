# A simple scheme interpreter

require "rsec"

class Scheme
  include Rsec::Helpers

  def initialize
    bra     = /\(\s*/.r.skip
    ket     = /\s*\)/.r.skip
    boolean = /\#[tf]/.    r.map {|n| ValueNode[n=='#t'] }
    integer = /0|[1-9]\d*/.r.map {|n| ValueNode[n.to_i]  }
    id      = /[^\s\(\)\[\]]+/.r.on {|n|
                def n.eval bind, *xs
                  bind[self]
                end
              }
    atom    = boolean | integer | id
    list    = nil # declare for lazy
    cell    = atom | lazy{list}
    list    = (   bra < cell.join(spacee)._? < ket   ).map {|(n)| ListNode[*n] }
    @parser = (spacee < cell.join(spacee)._? < spacee).map {|(n)| ListNode[*n] }
  end
      
  def run source
    @ctx = Rsec::ParseContext.new source, 'scm'
    res = @parser._parse @ctx
    if !res or !@ctx.eos?
      raise Rsec::ParseError['syntax error', @ctx]
    end
    res.eval Runtime.new
  end
  
  ValueNode = Struct.new :val
  class ValueNode
    def eval *xs
      val
    end
    def pretty_print q
      q.text "<#{val}>"
    end
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
    
    # define a function
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
        # (define (name plist[0]) body)
        when ListNode
          func, *xs = param
          self[func] = self['lambda'][bind, [xs, body]]
        # (define param body)
        when String
          self[param] = body.eval bind
        end
      end
      
      # declare:
      #   (lambda (xs[0] xs[1]) body)
      self['lambda'] = proc do |bind_def, (xs, body)|
        xs = [xs] if xs.is_a?(String)
        new_bind = Bind.new bind_def
        # calling:
        #   (some vs[0] vs[1])
        proc do |bind_call, vs|
          vs = vs.map{|v| v.eval bind_call}
          new_bind.merge! Hash[xs.zip vs]
          body.eval new_bind
        end
      end
      
      # lazy (short cut)
      self['if'] = proc do |bind, (p, left, right)|
        p.eval(bind) ? left.eval(bind) : right.eval(bind)
      end
      
      # misc
      %w|+ - * / ** % > <|.each do |s|
        define s, &s.to_sym
      end
      define '=', &:==
      define 'display' do |x|
        puts x
      end
    end
  end
end

s = Scheme.new
s.run File.read ARGV[0]

