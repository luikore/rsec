# BNF grammar parser
# http://en.wikipedia.org/wiki/Backus-Naur_form

require "rsec"

include Rsec::Helpers

def bnf
  literal   = /".*?"|'.*?'/.r
  rule_name = /\<.*?\>/.r 
  term      = literal | rule_name
  list      = term.join nb_spacee
  _or       = (nb_spacee < '|' < nb_spacee).map &:first
  expr      = list.join _or
  rule      = spacee < rule_name < nb_spacee < '::=' < nb_spacee < expr < spacee
  rule ** 1
end

require "pp"
pp bnf.parse! DATA.read

__END__
<syntax>     ::= <rule> | <rule> <syntax>
<rule>       ::= <opt-whitespace> "<" <rule-name> ">" <opt-whitespace> "::=" <opt-whitespace> <expression> <line-end>
<opt-whitespace> ::= " " <opt-whitespace> | ""
<expression> ::= <list> | <list> "|" <expression>
<line-end>   ::= <opt-whitespace> <EOL> | <line-end> <line-end>
<list>       ::= <term> | <term> <opt-whitespace> <list>
<term>       ::= <literal> | "<" <rule-name> ">"
<literal>    ::= '"' <text> '"' | "'" <text> "'"
