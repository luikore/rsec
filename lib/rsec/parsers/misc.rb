module Rsec #:nodoc

  # transform parse result
  class Map < Binary
    def _parse ctx
      res = left()._parse ctx
      return INVALID if INVALID[res]
      right()[res]
    end
  end

  # set expect tokens for parsing error in ctx<br/>
  # if left failed, the error would be registered
  class Fail < Binary
    def Fail.[] left, tokens
      # TODO mutex
      if @mask_bit > 1000
        raise "You've created too many fail parsers, If it is your intention, call Rsec::Fail.reset when previous expect settings can be thrown away."
      end
      parser = super(left, (1<<@mask_bit))
      @token_table[@mask_bit] = tokens
      @mask_bit += 1
      parser
    end

    def Fail.reset
      @mask_bit = 0
      @token_table = []
    end
    Fail.reset

    def Fail.get_tokens mask
      res = []
      @token_table.each_with_index do |tokens, idx|
        next unless tokens
        if (mask & (1<<idx)) > 0
          res += tokens
        end
      end
      res.uniq!
      res
    end

    def _parse ctx
      res = left()._parse ctx
      ctx.on_fail right if INVALID[res]
      res
    end
  end

  # look ahead
  class LookAhead < Binary
    def _parse ctx
      res = left()._parse ctx
      pos = ctx.pos
      return INVALID if INVALID[right()._parse ctx]
      ctx.pos = pos
      res
    end
  end

  # negative look ahead
  class NegativeLookAhead < Binary
    def _parse ctx
      res = left()._parse ctx
      pos = ctx.pos
      if INVALID[right()._parse ctx]
        ctx.pos = pos
        res
      end
    end
  end

  # branch combinator<br/>
  # result in one of the members, or INVALID
  class Branch < Unary
    def _parse ctx
      save_point = ctx.pos
      some.each do |e|
        res = e._parse ctx
        return res unless INVALID[res]
        ctx.pos = save_point
      end
      INVALID
    end
  end

  # matches a pattern
  class Pattern < Unary
    def _parse ctx
      ctx.scan some() or INVALID
    end
  end

  # scan until the pattern<br/>
  # for optimizing
  class UntilPattern < Unary
    def _parse ctx
      ctx.scan_until some() or INVALID
    end
  end

  # for optimization, not disposed to users
  class SkipPattern < Unary
    def _parse ctx
      ctx.skip some() or INVALID
    end
  end

  # for optimization, not disposed to users
  class SkipUntilPattern < Unary
    def _parse ctx
      ctx.skip_until some() or INVALID
    end
  end

  # should be end-of-file after parsing
  # FIXME seems parser keeps a state when using parse!, see nasm manual parse
  class Eof < Unary
    def _parse ctx
      ret = some()._parse ctx
      ctx.eos? ? ret : INVALID
    end
  end

  # one of char in string
  class OneOf < Unary
    def _parse ctx
      return INVALID if ctx.eos?
      chr = ctx.getch
      if some().index(chr)
        chr
      else
        ctx.pos = ctx.pos - 1
        INVALID
      end
    end
  end

  # one of char in string
  class OneOf_ < Unary
    def _parse ctx
      ctx.skip /\s*/
      return INVALID if ctx.eos?
      chr = ctx.getch
      unless some().index(chr)
        return INVALID
      end
      ctx.skip /\s*/
      chr
    end
  end

  # sometimes a variable is not defined yet<br/>
  # lazy is used to capture it later
  # NOTE the value is captured the first time it is called
  class Lazy < Unary
    def _parse ctx
      @some ||= \
        begin
          some()[]
        rescue NameError => ex
          some().binding.eval ex.name.to_s
        end
      @some._parse ctx
    end
  end
  
  # parse result is cached in ctx.
  # may improve performance
  class Cached
    include Parser
    
    def self.[] parser
      self.new parser
    end
    
    def initialize parser
      @parser = parser
      @salt = object_id() << 32
    end
    
    def _parse ctx
      key = ctx.pos | @salt
      cache = ctx.cache
      # result maybe nil, so don't use ||=
      if cache.has_key? key
        ret, pos = cache[key]
        ctx.pos = pos
        ret
      else
        ret = @parser._parse ctx
        pos = ctx.pos
        cache[key] = [ret, pos]
        ret
      end
    end
  end

end

