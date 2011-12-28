# string to be parsed
s = '(3+24/5)/10-3*4+((82321+12-3)-3*4+(82321+12-3))/5'

# rsec
$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "#{File.dirname(__FILE__)}/../examples/arithmetic"

p = arithmetic

require "profile"
1000.times{
  p.parse s
}
