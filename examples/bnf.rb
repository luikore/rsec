# BNF grammar parser
# http://en.wikipedia.org/wiki/Backus-Naur_form

require "rsec"

include Rsec::Helpers

def bnf
  nbsp      = /[\ \t]*/.r
  spacee    = /\s*/.r # include \n
  literal   = /".*?"|'.*?'/.r
  rule_name = /\<.*?\>/
  term      = literal | rule_name
  list      = term.join(nbsp).even
  expr      = list.join seq(nbsp, '|', nbsp)[1]
  rule      = seq_ rule_name, '::=', expr
  spacee.join(rule).eof
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
