require "#{File.dirname(__FILE__)}/helpers.rb"

class TestPrim < TC
  def test_floating
    [:double].each do |ty|
      p = prim ty
      ase INVALID, p.parse('d')
      ase 3.2e5.round, p.parse('+3.2e5').round
      ase INVALID, p.parse(' 4.8')

      p = prim ty, allowed_sign: ''
      ase 1.5e-3.round(4), p.parse('1.5E-3').round(4)
      ase INVALID, p.parse('+3.0')

      p = prim ty, allowed_sign: '-'
      ase (-5.0).round, p.parse('-5').round
      ase INVALID, p.parse('-')
      ase INVALID, p.parse('+5')
      ase 5.0.round, p.parse('5').round
      
      # with map block
      p = prim(ty){|x| x * 2 }
      ase 100.0.round, p.parse('50').round
    end
  end

  def test_hex_floating
    return # NOTE Ruby 1.9.3 removed Float() from hex values
    [:hex_double].each do |ty|
      p = prim ty
      ase Float('0x3.2').round(4), p.parse('0x3.2').round(4)

      # with map block
      p = prim(ty){|x| x - 0.1 }
      ase (Float('0x3.2') - 0.1).round(4), p.parse('0x3.2').round(4)
    end
  end

  def test_integer
    [:int32, :unsigned_int32, :int64, :unsigned_int64].each do |ty|
      p = prim ty
      ase 432, p.parse('432')
      p = prim ty, base: 4
      ase '120'.to_i(4), p.parse('120')
      p = prim ty, base: 35
      ase '1ax'.to_i(35), p.parse('1ax')
    end

    p = prim :int32, allowed_signs: '-'
    ase INVALID, p.parse('+12')
    ase INVALID, p.parse('123333333333333333333333333333333333')
    ase INVALID, p.parse('-')
    ase -49, p.parse('-49')

    assert_raise RuntimeError do
      prim :unsigned_int32, allowed_signs: '+-'
    end
  end
end

