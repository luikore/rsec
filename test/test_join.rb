require "#{File.dirname(__FILE__)}/helpers"

class TMisc < TC
  def test_join
    p0 = /\w{1,3}/.r.join '+'
    ase ['a','+','bc','+','d'], p0.parse('a+bc+d')
    p1 = [/[a-z]{1,3}/, '3'].r[0].join '+', /\s/
    ase %w[a + bc + d], p1.parse('a3 + bc3 + d3')
  end

  def test_skip_join
    p = /\d/.r.skip.join '+'
    ase ['+', '+'], p.parse('3+4+2')
  end
end
