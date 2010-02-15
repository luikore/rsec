require "#{File.dirname(__FILE__)}/helpers"

class TSeq < TC
  def test_lassoc
    p = 'a'.r < 'b' < 'c'
    ase ['a','b','c'], p.parse('abc')
    ase nil, p.parse('a')
    ase nil, p.parse('b')
    ase nil, p.parse('c')
    ase nil, p.parse('bc')
    ase nil, p.parse('ab')
  end
  
  def test_rassoc
    p = ('a'.r > 'b') > 'c'
    ase ['a',['b','c']], p.parse('abc')
  end
  
  def test_lassoc_s
    p = 'a'.r << ('b'.r < 'c')
    ase ['a', ['b','c']], p.parse('a  bc')
    ase nil, p.parse('ab c')
    ase nil, p.parse('a b c')
  end
  
  def test_rassoc_s
    p = 'a'.r >> ('b'.r > 'c')
    ase ['a',['b','c']], p.parse('a  bc')
    ase ['a',['b','c']], p.parse('abc')
    ase nil, p.parse('ab c')
    ase nil, p.parse('a b c')
  end
  
  def test_mix_assoc
    p = 'a'.r >> (('b'.r < 'c'.r) << 'd') > 'e'
    ase ["a", [["b", "c", 'd'], "e"]], p.parse('a bc de')
    ase nil, p.parse('ab cde')
  end
end
