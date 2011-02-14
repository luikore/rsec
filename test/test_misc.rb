require "#{File.dirname(__FILE__)}/helpers.rb"

class TMisc < TC
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
