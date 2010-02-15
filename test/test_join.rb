require "#{File.dirname(__FILE__)}/helpers"

class TMisc < TC
  def test_join
    p0 = /\w{1,3}/.r.join '+'
    p1 = /\w{1,3}/.r.ljoin '+'
    p2 = /\w{1,3}/.r.rjoin '+'
    ase ['a','+','bc','+','d'], p0.parse('a+bc+d')
    ase ['a','+','bc','+','d'], p1.parse('a+bc+d')
    ase ['a',['+',['bc',['+','d']]]], p2.parse('a+bc+d')
  end
end