require "#{File.dirname(__FILE__)}/helpers"

class TFall < TC
  def test_fall
    p = 'a'.r << 'b'
    ase 'a', p.parse('ab')
    ase nil, p.parse('b')
    p = 'a'.r >> 'b'
    ase 'b', p.parse('ab')
    ase nil, p.parse('b')
  end
end
