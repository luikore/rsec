module Rsec

  # primitive base
  module Prim
    def sign_strategy_to_pattern sign_strategy
      case sign_strategy
      when 3; '[\+\-]?'
      when 2; '\+?'
      when 1; '\-?'
      when 0; ''
      end
    end
  end

  # double precision float parser
  class PDouble < Binary
    include Prim

    def float_pattern sign_strategy, is_hex
      sign = sign_strategy_to_pattern sign_strategy
      if is_hex
        /#{sign}0x[\da-f]+(\.[\da-f]+)?/i
      else
        /#{sign}\d+(\.\d+)?(e[\+\-]?\d+)?/i
      end
    end

    def initialize sign_strategy, is_hex
      self.left = float_pattern sign_strategy, is_hex
    end

    def _parse ctx
      if (d = ctx.scan left)
        d = Float(d)
        return d if d.finite?
      end
      INVALID
    end
  end

  # primitive int parser commons
  class PInt < Binary
    include Prim

    def int_pattern sign_strategy, base
      sign = sign_strategy_to_pattern sign_strategy
      if base > 10
        d_hi = 9
        char_range = "a-#{('a'.ord + base - 11).chr}"
      else
        d_hi = base - 1
        char_range = ''
      end
      /#{sign}[0-#{d_hi}#{char_range}]+/i
    end

    def _parse ctx
      if (d = ctx.scan left)
        d = d.to_i @base
        return d if right.include?(d)
      end
      INVALID
    end
  end

  # 32-bit int parser
  class PInt32 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = (-(1<<31))..((1<<31)-1)
    end
  end

  # unsigned 32 bit int parser
  class PUnsignedInt32 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = 0...(1<<32)
    end
  end

  # 64-bit int parser
  class PInt64 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = (-(1<<63))..((1<<63)-1)
    end
  end

  # unsigned 64-bit int parser
  class PUnsignedInt64 < PInt
    def initialize sign_strategy, base
      @base = base
      self.left = int_pattern sign_strategy, base
      self.right = 0...(1<<64)
    end
  end

end
