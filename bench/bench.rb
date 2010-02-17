# Compare performance between rsec and treetop
# NOTE simple parser doesn't require much backtracking, so treetop's caching is sure to fail.
#      Next step is to compare really complex parsers.

# string to be parsed
s = '(3+24/5)/10-3*4+((82321+12-3)-3*4+(82321+12-3))/5'

# rsec
require "#{File.dirname(__FILE__)}/../examples/arithmetic"
p = arithmetic()

# treetop
require "treetop"
require "#{File.dirname(__FILE__)}/little.rb"
t = ArithmeticParser.new

require "benchmark"

# ------------------------------------------------------------------------------

print 'rsec result:'
puts p.parse! s
puts((Benchmark.measure{
  1000.times {
    p.parse! s
  }
}), '')

print 'treetop result:'
puts t.parse(s).value
puts((Benchmark.measure {
  1000.times {
    t.parse(s).value
  }
}), '')

puts 'treetop without calculation'
puts((Benchmark.measure {
  1000.times {
    t.parse s
  }
}), '')

puts 'treetop calculation only'
tt_ast = t.parse s
puts((Benchmark.measure {
  1000.times {
    tt_ast.value
  }
}), '')

