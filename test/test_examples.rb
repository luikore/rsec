dir = File.dirname __FILE__
require "#{dir}/helpers"
require "#{dir}/../examples/arithmetic"
require "#{dir}/../examples/higher_arithmetic"
require "#{dir}/../examples/s_exp"

class TExamples < TC
  def initialize *xs
    super(*xs)
    @a = arithmetic()
    @ha = higher_arithmetic()
    @se = s_exp()
  end
  
  def test_arithmetic
    s = '1+(2- (3+ 4))/5 * 2*4 +1'
    ase eval(s), @a.parse(s)
    s = '1+(2- (3+ 4))/5 * 2**4 +1'
    ase eval(s), @ha.parse(s)
  end
  
  def test_s_exp
    res = @se.parse '(a 3 4.3 (add 1 3) (minus (multi 4 5)))'
    expected = ['a', 3.0, 4.3, ['add', 1, 3], ['minus', ['multi', 4, 5]]]
    ase expected, res
    
    res = @se.parse '(a (3) ce2 (add 1 3))'
    expected = ['a', 3.0, 'ce2', ['add', 1, 3]]
    ase expected, res
  end
end