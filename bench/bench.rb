# Compare performance between rsec and treetop
# NOTE simple parser doesn't require much backtracking, so treetop's caching is sure to fail.
#      Next step is to compare really complex parsers.

# string to be parsed
s = '(3+24/5)/10-3*4+((82321+12-3)-3*4+(82321+12-3))/5'

# rsec
$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "#{File.dirname(__FILE__)}/../examples/arithmetic"
require "#{File.dirname(__FILE__)}/../examples/arithmetic_rpn"

# treetop
require "treetop"
require "#{File.dirname(__FILE__)}/little.rb"

require "benchmark"

# ------------------------------------------------------------------------------

puts ''
puts Benchmark::CAPTION
puts ''

print 'rsec result:', "\t"
p = arithmetic()
puts p.parse! s
puts((Benchmark.measure{
  1000.times {
    p.parse! s
  }
}), '')

print 'rsec rpn:', "\t"
p = arithmetic_rpn()
p p.parse! s
puts((Benchmark.measure{
  1000.times {
    p.parse! s
  }
}), '')

print 'treetop result:', "\t"
t = ArithmeticParser.new
puts t.parse(s).value
puts((Benchmark.measure {
  1000.times {
    t.parse(s).value
  }
}), '')

puts 'treetop without calculation'
t = ArithmeticParser.new
puts((Benchmark.measure {
  1000.times {
    t.parse s
  }
}), '')

PARSEC_ARITH_SO = "#{File.dirname(__FILE__)}/parsec/Arithmetic.so"
if File.exist?(PARSEC_ARITH_SO)
  require 'dl/import'
  require 'dl/types'
  module Arithmetic
    extend DL::Importer
    dlload "#{File.dirname(__FILE__)}/parsec/Arithmetic.so"
    extern "long calculate(char *)", :stdcall
    extern "long donothing(char *)", :stdcall
  end
  print 'parsec result:', "\t"
  puts Arithmetic.calculate s
  puts((Benchmark.measure {
    1000.times {
      Arithmetic.calculate s
    }
  }), '')
else
  puts 'parsec benchmark requires ghc installation. cd bench/parsec and run make.sh(unix) or make.bat(windows)'
end

