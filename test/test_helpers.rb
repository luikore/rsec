require "#{File.dirname(__FILE__)}/helpers.rb"

class THelpers < TC
  def test_block
    p1 = nil
    p2 = lazy{p1}
    p3 = dynamic{p1}
    
    p1 = '3'.r
    asp '3', p2
    asp '3', p3
    
    p1 = '4'.r
    asp '3', p2
    asp '4', p3
  end
  
  def test_eof
    p = ''.r.eof
    asp '', p
    ase INVALID, p.parse('a')
  end
  
  def test_skip_n
    p = skip_n(3).eof
    ase SKIP, p.parse('abc')
    ase INVALID, p.parse('a')
    ase INVALID, p.parse('abcd')
  end
  
  def test_bol
    p = bol.eof
    ase SKIP, p.parse('')
    p = bol(3).eof
    ase 3, p.parse('')
    ase INVALID, p.parse('1')
  end
  
  def test_value
    p = value(5).eof
    ase 5, p.parse('')
    ase INVALID, p.parse('a')
  end
end
