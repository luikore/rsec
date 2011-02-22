require "#{File.dirname(__FILE__)}/helpers.rb"

class TestOneOf < TC
  def test_one_of
    p = one_of('abcd')
    ase 'c', p.parse('c')
    ase INVALID, p.parse('e')
    p = one_of('+=')
    ase '=', p.parse('=')

    begin
      p = one_of('')
      assert false, "should raise exception for empty string"
    rescue
    end

    # with map block
    p = one_of('x+'){|v| v * 2}
    ase '++', p.parse('+')
  end

  def test_one_of_
    p = one_of_('abcd')
    ase 'a', p.parse('a')
    ase INVALID, p.parse('e')
    ase 'd', p.parse(' d ')
    ase 'a', p.parse(' a')
    ase 'c', p.parse('c ')

    assert_raise(ArgumentError) {
      p = one_of_('')
    }

    # with map block
    p = one_of_('w'){'v'}
    ase 'v', p.parse('w')
  end

end
