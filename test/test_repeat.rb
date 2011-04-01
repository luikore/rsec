require "#{File.dirname(__FILE__)}/helpers.rb"

class TestRepeat < TC
  def test_maybe
    [:_?, :maybe].each do |m|
      p = seq('v', 'q').send m
      ase [], p.parse('')
      ase INVALID, p.eof.parse('v')
      ase [['v', 'q']], p.parse('vq')

      # with map block
      p = seq('v', 'q').maybe {|x| x.empty? ? 'bad' : 'good' }
      ase 'good', p.parse('vq')
    end
  end

  def test_multiply
    p = ('ce'.r * 3).eof
    ase ['ce','ce','ce'], (p.parse 'cecece')
    ase INVALID, (p.parse 'cece')
    ase INVALID, (p.parse 'cececece')
    
    p = ('ce'.r * 0).eof
    ase [], (p.parse '')
    ase INVALID, (p.parse 'ce')
  end
  
  def test_range
    p = ('ce'.r * (2..3)).eof
    ase INVALID, (p.parse 'ce')
    ase ['ce','ce'], (p.parse 'cece')
    ase INVALID, (p.parse 'cececece')
  end
  
  def test_inf
    p = ('ce'.r * (3..-1)).eof
    ase INVALID,
      (p.parse 'cece')
    ase ['ce','ce','ce'],
      (p.parse 'cecece')
    ase ['ce','ce','ce','ce','ce'],
      (p.parse 'cecececece')
  end

  def test_star
    p = '*'.r.star
    ase [], p.parse('')
    ase %w[* * *], p.parse('***')
  end
end
