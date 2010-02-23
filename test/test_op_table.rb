require "#{File.dirname(__FILE__)}/helpers"

class TOpTable < TC
  def test_op_table
    p = /\w+/.r.join_infix_operators \
      space: /\s*/,
      left: {'+'=>5, '-'=>5, '*'=>20, '/'=>20, '**' => 30},
      right: {'='=>0}
    ase ["a", "b", "3", "*", "4", "5", "*", "+", "="], p.parse('a=b*3 + 4*5')
  end
end
