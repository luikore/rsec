require "#{File.dirname(__FILE__)}/helpers.rb"

class TestJoin < TC
  def test_join
    p0 = /\w{1,3}/.r.join '+'
    ase ['abc'], p0.eof.parse('abc')
    ase ['a','+','bc','+','d'], p0.parse('a+bc+d')
    ase INVALID, p0.eof.parse('a+ bc+d')
    ase INVALID, p0.eof.parse('a+b+')

    p1 = seq(/[a-z]{1,3}/, '3')[0].join seq(/\s/.r, '+', /\s/)[1]
    ase ['abc'], p1.eof.parse('abc3')
    ase %w[a + bc + d], p1.parse('a3 + bc3 + d3')
    ase INVALID, p1.eof.parse('a+b+')
  end

  def test_nest_join
    p = 'a'.r.join(/\s*\*\s*/.r).join(/\s*\+\s*/.r)
    ase [['a'], ' + ', ['a', ' * ', 'a'], ' +', ['a']], p.parse('a + a * a +a')
  end

  def test_join_with_mapping_block
    p = 'a'.r.join('+'){|res| res.grep /\+/ }
    ase ['+', '+'], p.parse('a+a+a')
    ase [], p.parse('a')
  end

  def test_join_even
    p = 'a'.r.join('+').even
    ase %w[a a a], p.parse('a+a+a')
    ase %w[a], p.parse('a')
    ase INVALID, p.eof.parse('a+')
    ase INVALID, p.parse('b')
    ase INVALID, p.parse('')
  end

  def test_join_odd
    p = 'a'.r.join('+').odd
    ase %w[+ +], p.parse('a+a+a')
    ase [], p.parse('a')
    ase INVALID, p.parse('')
    ase INVALID, p.parse('+')
    ase INVALID, p.parse('b')
  end

  def test_nest_join_even_odd
    p = 'a'.r.join('+').odd.join('*')
    ase [['+'], '*', []], p.parse('a+a*a')
    p = 'a'.r.join('+').even.join('*')
    ase [['a','a'], '*', ['a']], p.parse('a+a*a')
  end
end
