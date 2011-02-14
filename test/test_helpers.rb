require "#{File.dirname(__FILE__)}/helpers.rb"

class THelpers < TC
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
  
  def test_skip_n
    # skip 3 chars and return SKIP
    p = skip_n(3).eof
    ase SKIP, p.parse('abc')
    ase INVALID, p.parse('a')
    ase INVALID, p.parse('abcd')

    # skip with mapping
    p = skip_n(2){'test block'}
    asp 'test block', p
  end
  
  def test_bol
    # begin of line
    p = bol.eof
    ase SKIP, p.parse('')
    p = bol(3).eof
    ase 3, p.parse('')
    ase INVALID, p.parse('1')

    # with block
    p = bol{'bol'}.eof
    ase 'bol', p.parse('')
    ase 'bol', seq("\n", p)[1].parse("\n")
  end
  
end

