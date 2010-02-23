require "#{File.dirname(__FILE__)}/helpers"

class TLookAhead < TC
  def test_lookahead
    p1 = 'a'.r & 'b'
    p2 = /\w/.r
    p = [p1, p2].r
    ase ['a', 'b'], p.parse('ab')
    ase nil, p.parse('ac')
    
    p1 = 'a'.r ^ 'b'
    p = [p1, p2].r
    ase ['a', 'c'], p.parse('ac')
    ase nil, p.parse('ab')
  end
end
