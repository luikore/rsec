require "#{File.dirname(__FILE__)}/helpers.rb"

class TSeq < TC
  def test_seq
    p = ['a', 'b', 'c'].r
    ase ['a','b','c'], p.parse('abc')
    ase INVALID, p.parse('a')
    ase INVALID, p.parse('b')
    ase INVALID, p.parse('c')
    ase INVALID, p.parse('bc')
    ase INVALID, p.parse('ab')
  end

  def test_seq_skip
    p = %w[abc ef vv].r skip: /\s+/
    ase %w[abc ef vv], p.parse("abc    ef vv")
    ase INVALID, p.parse("abcef vv")
  end

  def test_seq_mix
    p = ['e', ['a','b','c'].r, 'd'].r
    ase ['e', ['a','b','c'], 'd'], p.parse('eabcd')
  end
  
  def test_seq_one
    p = ['a', 'b', 'c'].r[1]
    ase 'b', p.parse('abc')
    p = ['abc', /\s*/.r.skip, 'd'].r[1]
    ase 'd', p.parse('abc d')
  end
end
