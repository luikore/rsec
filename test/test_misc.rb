require "#{File.dirname(__FILE__)}/helpers"

class TMisc < TC
  def test_wrap
    p = 'a'.r < ('b'.r < 'c').wrap < 'd'
    ase ['a',['b','c'],'d'], p.parse('abcd')
  end
  
  def test_map
    p = /\w/.r.map{|n| n*2}
    ase 'bb', p.parse('b')
  end
  
  def test_on
    v = nil
    p = 'x'.r.on{|n| v = n+'v'}
    p.parse 'x'
    ase 'xv',v
  end
  
  def test_fail
    p = 'v'.r.fail 'omg!'
    p.parse! 'u'
  rescue => e
    assert(e.to_s.index('omg!') >= 0)
  end
end