require "#{File.dirname(__FILE__)}/helpers.rb"

class TestSeq < TC
  def test_seq
    p = seq('a', 'b', 'c')
    ase ['a','b','c'], p.parse('abc')
    ase INVALID, p.parse('a')
    ase INVALID, p.parse('b')
    ase INVALID, p.parse('c')
    ase INVALID, p.parse('bc')
    ase INVALID, p.parse('ab')
  end

  def test_seq_
    p = seq_('abc', 'ef', 'vv')
    ase %w[abc ef vv], p.parse("abc    ef vv")
    p = seq_('abc', 'ef', 'vv', skip: /\s+/)
    ase %w[abc ef vv], p.parse("abc    ef vv")
    ase INVALID, p.parse("abcef vv")
  end

  def test_seq_mix
    p = seq('e', seq_('a','b','c'), 'd')
    ase ['e', ['a','b','c'], 'd'], p.parse('eabcd')
  end
  
  def test_seq_one
    p = seq('a', 'b', 'c')[1]
    ase 'b', p.parse('abc')
    p = seq('abc', /\s*/, 'd')[2]
    ase 'd', p.parse('abc d')
  end

  def test_seq_one_
    p = seq_('a', 'b', 'c')[1]
    ase 'b', p.parse('a bc')
    p = seq_('abc', /\s*/, 'd')[2]
    ase 'd', p.parse('abc d')
  end

  def test_fall
    p = 'a'.r >> 'b'
    ase 'b', p.parse!('ab')
    p = p << 'c'
    ase 'b', p.parse!('abc')

    p = p._?
    ase ['b'], p.eof.parse!('abc')
    ase [], p.eof.parse!('')
  end
end
