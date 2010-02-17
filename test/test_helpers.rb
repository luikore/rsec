require "#{File.dirname(__FILE__)}/helpers"

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
  
  def test_skip_n
    p = skip_n 3
    ase :_skip_, p.parse('abc')
    ase nil, p.parse('a')
    ase nil, p.parse('abcd')
  end
  
  def test_bol
    p = bol
    ase :_skip_, p.parse('')
    p = bol 3
    ase 3, p.parse('')
    ase nil, p.parse('1')
  end
  
  def test_value
    p = value(5)
    ase 5, p.parse('')
    ase nil, p.parse('a')
  end
  
  def test_spaces
    ase nil, space.parse('')
    ase :_skip_, space.parse(" \t")
    ase :_skip_, space.parse("\r\n   \t ")
    
    ase :_skip_, spacee.parse('')
    ase :_skip_, spacee.parse("\t ")
    ase :_skip_, spacee.parse("\r \n")

    ase nil, nb_space.parse('')
    ase :_skip_, nb_space.parse("\t ")
    ase nil, nb_space.parse("\r \n")
    
    ase :_skip_, nb_spacee.parse('')
    ase :_skip_, nb_spacee.parse("\t ")
    ase nil, nb_spacee.parse("\r \n")
  end
end