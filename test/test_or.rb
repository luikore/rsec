require "#{File.dirname(__FILE__)}/helpers.rb"

class TOr < TC
  def test_or
    p = 'a'.r | /\d+/ | ['c', 'd'].r
    ase ['c','d'], p.parse('cd')
    ase '3', p.parse('3')
    ase INVALID, p.parse('c')

    p = 'x'.r | 'y'
    ase INVALID, p.parse('')
    ase 'y', p.parse('y')
  end
end
