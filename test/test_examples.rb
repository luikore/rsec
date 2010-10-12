$:.unshift File.dirname __FILE__
require "helpers"
$:.unshift File.expand_path "#{File.dirname __FILE__}/../examples"
require "arithmetic"
require "arithmetic_rpn"
require "s_exp"

class TExamples < TC
  def initialize *xs
    super(*xs)
    @a = arithmetic()
    @a_rpn = arithmetic_rpn()
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

    ase 2, @a_rpn.parse('1+1')
    ase 11, @a_rpn.parse('2+ 3*3')
    ase 0, @a_rpn.parse('2 - (1+ 1*1**3)')
    s = '1+(2- (3+ 4))/5 * 2**4 +1'
    ase eval(s), @a_rpn.parse(s)
  end
  
  def test_s_exp
    res = @s_exp.parse '(a 3 4.3 (add 1 3) (minus (multi 4 5)))'
    expected = ['a', 3.0, 4.3, ['add', 1, 3], ['minus', ['multi', 4, 5]]]
    ase expected, res
    
    res = @s_exp.parse '(a (3) ce2 (add 1 3))'
    expected = ['a', 3.0, 'ce2', ['add', 1, 3]]
    ase expected, res
  end
end
