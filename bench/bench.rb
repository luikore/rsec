# Compare performance between rsec and treetop
# NOTE simple parser doesn't require much backtracking, so treetop's caching is sure to fail.
#      Next step is to compare really complex parsers.

# string to be parsed
s = '(3+24/5)/10-3*4+((82321+12-3)-3*4+(82321+12-3))/5'

# rsec
$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "#{File.dirname(__FILE__)}/../examples/arithmetic"

# treetop
require "treetop"
require "#{File.dirname(__FILE__)}/little.rb"

require "benchmark"

def measure &proc
  puts proc[]
  200.times &proc
  puts((Benchmark.measure{
    1000.times &proc
  }), '')
end

# ------------------------------------------------------------------------------

puts ''
puts Benchmark::CAPTION
puts ''

print 'rsec result:', "\t"
p = arithmetic()
measure{ p.parse! s }

print 'treetop result:', "\t"
t = ArithmeticParser.new
measure{ t.parse(s).value }

puts 'treetop without calculation'
t = ArithmeticParser.new
measure{ t.parse s }

PARSEC_ARITH_SO = "#{File.dirname(__FILE__)}/parsec/Arithmetic.so"
if File.exist?(PARSEC_ARITH_SO)
  require 'dl/import'
  require 'dl/types'
  module Arithmetic
    extend DL::Importer
    dlload PARSEC_ARITH_SO
    extern "long calculate(char *)", :stdcall
    extern "long donothing(char *)", :stdcall
  end
  print 'Haskell Parsec result:', "\t"
  measure{ Arithmetic.calculate s }
else
  puts 'Haskell Parsec benchmark requires ghc installation. cd bench/parsec and run make.sh(unix) or make.bat(windows)'
end

