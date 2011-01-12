require "#{File.dirname(__FILE__)}/helpers.rb"

class TOneOf < TC
  def test_one_of
    p = one_of('abcd')
    ase 'c', p.parse('c')
    ase INVALID, p.parse('e')
    p = one_of('+=')
    ase '=', p.parse('=')
  end

  def test_one_of_
    p = one_of_('abcd')
    ase 'a', p.parse('a')
    ase INVALID, p.parse('e')
    ase 'd', p.parse(' d ')
    ase 'a', p.parse(' a')
    ase 'c', p.parse('c ')
  end

  def test_one_of_and_fall
    p = one_of_('+-') << 'b'
    ase '-', p.parse('-b')
    p = 'a'.r >> one_of('+-')
    ase '-', p.parse('a-')
  end

end
