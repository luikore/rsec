require "#{File.dirname(__FILE__)}/helpers.rb"

class TPattern < TC
  def test_create
    p1 = 'abc'.r
    ase /abc/.r, p1
    asp 'abc', p1
    
    asr do
      p1.eof.parse! 'abcd'
    end
    ase INVALID, p1.eof.parse('abcd')
    
    asr do 
      p1.eof.parse! 'xabc'
    end
    ase INVALID, p1.eof.parse('xabc')
  end

  def test_skip
    p = 'ef'.r.skip
    ase SKIP, p.parse('ef')
    ase INVALID, p.parse('bb')
  end

  def test_until
    p = 'ef'.r.until
    asp 'xef', p
    asp "x\nef", p
  end

  def test_skip_until
    p = /\d\w+\d/.r.until.skip
    ase SKIP, p.parse("bcd\n3vve4")
    ase INVALID, p.eof.parse("bcd\n3vve4-")
  end
end
