require "#{File.dirname(__FILE__)}/helpers.rb"

class TBranch < TC
  def test_branch
    p = branch('a', /\d+/, seq('c', 'd'))
    ase ['c','d'], p.parse('cd')
    ase '3', p.parse('3')
    ase INVALID, p.parse('c')

    p = branch('x', 'y')
    ase INVALID, p.parse('')
    ase 'y', p.parse('y')
  end
end
