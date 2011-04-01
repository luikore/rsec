require "#{File.dirname(__FILE__)}/helpers.rb"

class TestRsec < TC
  def test_try_skip_pattern
    p = Rsec.try_skip_pattern 'abc'.r
    ase Rsec::SkipPattern, p.class
    p = Rsec.try_skip_pattern 'abc'.r.until
    ase Rsec::SkipUntilPattern, p.class
  end
end
