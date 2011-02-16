require "#{File.dirname(__FILE__)}/helpers.rb"

class TMisc < TC
  def test_lazy
    p1 = nil
    p2 = lazy{p1}
    
    p1 = '3'.r
    asp '3', p2
    
    p1 = '4'.r
    asp '3', p2

    p2 = lazy{p7} # don't have to define p7 before lazy
    p7 = '5'.r
    asp '5',p2
  end
  
  def test_eof
    p = ''.r.eof
    asp '', p
    ase INVALID, p.parse('a')
  end

  def test_cache
    p1 = seq('a', seq('b', 'c'))
    p = seq(p1.cached, 'd')
    ase [['a',['b','c']],'d'], p.parse('abcd')

    # with map block
    p = seq(p1.cached{ 'mapped' }, 'd')
    ase ['mapped', 'd'], p.parse('abcd')
  end
  
  def test_map
    p = /\w/.r.map{|n| n*2}
    ase 'bb', p.parse('b')
    ase INVALID, p.parse('.')
  end
  
  def test_fail
    p = 'v'.r.fail 'omg!'
    p.eof.parse! 'u'
  rescue => e
    assert e.to_s.index 'omg!'
  end
  
  def test_fail_with_block
    p = 'v'.r.fail('omg!'){ 'should fail' }
    p.eof.parse! 'u'
  rescue => e
    assert e.to_s.index 'omg!'
  end

  def test_maybe
    [:_? , :maybe].each do |m|
      p = seq('v', 'q').send m
      ase SKIP, p.parse('')
      ase INVALID, p.eof.parse('v')
      ase ['v', 'q'], p.parse('vq')

      # with map block
      p = seq('v', 'q').maybe {|x| SKIP[x] ? SKIP : 'good' }
      ase 'good', p.parse('vq')
    end
  end
end
