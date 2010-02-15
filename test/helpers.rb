# coding: utf-8

$dir = File.dirname(__FILE__)
require "#{$dir}/../lib/rsec"
require "test/unit"
include Rsec::Helpers

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

