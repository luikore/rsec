require "#{File.dirname(__FILE__)}/helpers.rb"

class TestPattern < TC
  def test_create
    p1 = 'x'.r
    asp 'x', p1
    p1 = 'abc'.r
    asp 'abc', p1
    
    asr do
      p1.eof.parse! 'abcd'
    end
    ase INVALID, p1.eof.parse('abcd')
    
    asr do 
      p1.eof.parse! 'xabc'
    end
    ase INVALID, p1.eof.parse('xabc')

    # with map block
    p = 'x'.r{ 'y' }
    ase INVALID, p.parse('y')
    ase 'y', p.parse('x')
  end

  def test_until
    p = 'ef'.r.until
    asp 'xef', p
    asp "x\nef", p
    
    p = 'e'.r.until
    asp 'xe', p
    asp "x\ne", p

    # with map block
    p = 'e'.r.until{|s| s*2}
    ase 'xexe', p.parse('xe')
  end

  def test_word
    p = word('abc')
    ase INVALID, p.parse('abcd')
    ase INVALID, seq_(p, 'd').parse('abcd')
    ase 'abc', p.parse('abc')
    ase ['abc', 'd'], seq_(p, 'd').parse('abc d')
  end

  def test_symbol
    p = symbol('*')
    ase '*', p.parse(' * ')
  end

end
