require "#{File.dirname(__FILE__)}/helpers.rb"

class TMisc < TC
  def test_join
    p0 = /\w{1,3}/.r.join '+'
    ase ['abc'], p0.eof.parse('abc')
    ase ['a','+','bc','+','d'], p0.parse('a+bc+d')
    ase INVALID, p0.eof.parse('a+ bc+d')
    ase INVALID, p0.eof.parse('a+b+')

    p1 = [/[a-z]{1,3}/, '3'].r[0].join '+', /\s/
    ase ['abc'], p1.eof.parse('abc3')
    ase %w[a + bc + d], p1.parse('a3 + bc3 + d3')
    ase INVALID, p1.eof.parse('a+b+')
  end

  def test_skip_join
    p = /\d/.r.skip.join '+'
    ase ['+', '+'], p.parse('3+4+2')
  end

  def test_join_skip
    p = /\d/.r.join '+'.r.skip
    ase ['3','4','2'], p.parse('3+4+2')
  end
end
