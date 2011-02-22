require "#{File.dirname(__FILE__)}/helpers.rb"

class TestBranch < TC
  def test_branch
    p = 'a'.r | /\d+/ | seq('c', 'd')
    ase ['c','d'], p.parse('cd')
    ase '3', p.parse('3')
    ase INVALID, p.parse('c')

    p = 'x'.r | 'y'
    ase INVALID, p.parse('')
    ase 'y', p.parse('y')
  end
end
