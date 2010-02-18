require "#{File.dirname(__FILE__)}/helpers"

class TMisc < TC
  def test_cache
    p = 'a'.r < ('b'.r < 'c').cached < 'd'
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
    p.eof.parse! 'u'
  rescue => e
    assert e.to_s.index 'omg!'
  end
  
  def test_maybe
    [:_? , :maybe].each do |m|
      p = ('v'.r < 'q').send m
      ase :_skip_, p.parse('')
      ase ['v', 'q'], p.parse('vq')
    end
  end
end