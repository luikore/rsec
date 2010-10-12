require "#{File.dirname(__FILE__)}/helpers.rb"

class TFall < TC
  def test_fall
    p = 'a'.r << 'b'
    ase 'a', p.parse('ab')
    ase INVALID, p.parse('b')
    ase INVALID, p.parse('')
    p = 'a'.r >> 'b'
    ase 'b', p.parse('ab')
    ase INVALID, p.parse('b')
    ase INVALID, p.parse('')
  end

  def test_mixed_fall
    p = ('a'.r << 'b' << 'c').eof
    ase 'a', p.parse('abc')
    ase INVALID, p.parse('a')
    ase INVALID, p.parse('ab')

    p = ('a'.r >> 'b' >> 'c').eof
    ase 'c', p.parse('abc')
    ase INVALID, p.parse('bc')
    ase INVALID, p.parse('ab')
    ase INVALID, p.parse('a')

    p = ('a'.r >> 'b' << 'c').eof
    ase 'b', p.parse('abc')
    ase INVALID, p.parse('ab')

    p = ('a'.r << 'b' >> 'c').eof
    ase 'c', p.parse('abc')
    ase INVALID, p.parse('c')
  end
end
