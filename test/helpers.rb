# coding: utf-8

$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "rsec"
include Rsec::Helpers
require "test/unit"

TC = Test::Unit::TestCase
module Test::Unit::Assertions
  alias ase assert_equal
  def asr
    assert_raise(Rsec::ParseError) { yield }
  end
  # assert parse returns the string
  def asp s, p
    assert_equal(s, p.parse(s))
  end
end

