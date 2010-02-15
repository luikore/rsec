require "#{File.dirname(__FILE__)}/helpers"

class TPattern < TC
  def test_create
    p1 = 'abc'.r
    ase /abc/.r, p1
    asp 'abc', p1
    asr do
      p1.parse! 'abcd'
    end
    ase nil, p1.parse('abcd')
    asr do 
      p1.parse! 'xabc'
    end
    ase nil, p1.parse('xabc')
  end

  def test_skip
    p = 'ef'.r.skip
    ase :_skip_, p.parse('ef')
    ase nil, p.parse('bb')
  end

  def test_until
    p = 'ef'.r.until
    asp 'xef', p
    asp "x\nef", p
  end

  def test_skip_until
    p = /\d\w+\d/.r.skip_until
    ase :_skip_, p.parse("bcd\n3vve4")
    ase nil, p.parse("bcd\n3vve4-")
    p2 = 'vos'.r.until.skip
    ase 'vos'.r.skip_until, p2
  end
end
