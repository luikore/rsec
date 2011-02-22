require "#{File.dirname(__FILE__)}/helpers.rb"
$:.unshift "#{File.dirname __FILE__}/../examples"
require "arithmetic"
require "s_exp"

class TestExamples < TC
  def initialize *xs
    super(*xs)
    @a = arithmetic()
    @s_exp = s_exp()
  end
  
  def test_arithmetic
    # step by step
    s = '1'
    ase eval(s), @a.parse(s)
    s = '3+ 2'
    ase eval(s), @a.parse(s)
    s = '5-2*1'
    ase eval(s), @a.parse(s)
    s = '(2)'
    ase eval(s), @a.parse(s)
    s = '1+(2- (3+ 4))/5 * 2*4 +1'
    ase eval(s), @a.parse(s)
  end
  
  def test_s_exp
    res = @s_exp.parse! '(a 3 4.3 (add 1 3) (minus (multi 4 5)))'
    expected = ['a', 3.0, 4.3, ['add', 1, 3], ['minus', ['multi', 4, 5]]]
    ase expected, res
    
    res = @s_exp.parse! '(a (3) ce2 (add 1 3))'
    expected = ['a', 3.0, 'ce2', ['add', 1, 3]]
    ase expected, res
  end
end
