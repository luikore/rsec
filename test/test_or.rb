require "#{File.dirname(__FILE__)}/helpers"

class TOr < TC
  def test_or
    p = 'a'.r | /\d+/ | ['c', 'd'].r
    ase ['c','d'], p.parse('cd')
    ase '3', p.parse('3')
    ase nil, p.parse('c')
  end
end