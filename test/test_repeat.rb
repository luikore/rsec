require "#{File.dirname(__FILE__)}/helpers"

class TPattern < TC
  def test_multiply
    p = 'ce'.r * 3
    ase ['ce','ce','ce'], (p.parse 'cecece')
    ase nil, (p.parse 'cece')
    ase nil, (p.parse 'cececece')
    
    p = 'ce'.r * -4
    ase ['ce',['ce',['ce','ce']]], (p.parse 'cececece')
    
    p = 'ce'.r * 0
    ase [], (p.parse '')
    ase nil, (p.parse 'ce')
  end
  
  def test_range
    p = 'ce'.r * (2..3)
    ase nil, (p.parse 'ce')
    ase ['ce','ce'], (p.parse 'cece')
    ase nil, (p.parse 'cececece')
    
    p = /\d?[a-z]/.r * (-3..4)
    ase nil, (p.parse '3ab')
    ase ['3a',['c','d']], (p.parse '3acd')
    ase nil, (p.parse '3acdef')
  end
  
  def test_inf
    p = 'ce'.r * (3..-1)
    ase nil,
      (p.parse 'cece')
    ase ['ce','ce','ce'],
      (p.parse 'cecece')
    ase ['ce','ce','ce','ce','ce'],
      (p.parse 'cecececece')
  end
end
