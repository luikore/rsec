require "#{File.dirname(__FILE__)}/helpers.rb"

class TWrap < TC
  def test_wrap
    p = 'xyz'.r.wrap '()'
    ase 'xyz', p.parse('(xyz)')
    p = ''.r.wrap '[]'
    ase '', p.parse('[]')
  end

  def test_wrap_
    p = 'a'.r.wrap_ '||'
    ase 'a', p.parse('| a|')
    ase 'a', p.parse('| a  |')
    ase 'a', p.parse('|a|')
  end
end
