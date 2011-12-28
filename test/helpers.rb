# coding: utf-8

$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "rsec"
include Rsec::Helpers
require "test/unit"

TC = Test::Unit::TestCase
class TC
  INVALID = Rsec::INVALID
end

module Test::Unit::Assertions
  alias ase assert_equal
  def asr
    assert_raise(Rsec::SyntaxError) { yield }
  end
  # assert parse returns s
  def asp s, p
    assert_equal(s, p.parse(s))
  end
end

