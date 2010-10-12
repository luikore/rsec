require "#{File.dirname(__FILE__)}/helpers.rb"

class TMisc < TC
  def test_cache
    p1 = ['a', ['b', 'c'].r].r
    p = [p1.cached, 'd'].r
    ase [['a',['b','c']],'d'], p.parse('abcd')
  end
  
  def test_map
    p = /\w/.r.map{|n| n*2}
    ase 'bb', p.parse('b')
    ase INVALID, p.parse('.')
  end
  
  def test_on
    v = nil
    p = 'x'.r.on{|n| v = n+'v'}
    ase 'x', p.parse('x')
    ase 'xv', v # changed

    v = 3
    ase INVALID, p.parse('v')
    ase 3, v # not changed
  end
  
  def test_fail
    p = 'v'.r.fail 'omg!'
    p.eof.parse! 'u'
  rescue => e
    assert e.to_s.index 'omg!'
  end
  
  def test_maybe
    [:_? , :maybe].each do |m|
      p = ['v', 'q'].r.send m
      ase SKIP, p.parse('')
      ase INVALID, p.eof.parse('v')
      ase ['v', 'q'], p.parse('vq')
    end
  end
end
