# coding: utf-8
# ------------------------------------------------------------------------------
# Parser Base

module Rsec #:nodoc:
  # parses string<br/>
  # returns nil if unparsed
  def parse str, source_name='source'
    ctx = ParseContext.new str, source_name
    _parse ctx
  end

  # almost the same as parse<br/>
  # but raises ParseError
  def parse! str, source_name='source'
    ctx = ParseContext.new str, source_name
    ret = _parse ctx
    if INVALID[ret]
      raise ParseError[ctx.err || 'syntax error', ctx]
    end
    ret
  end

  # parse context inherits from StringScanner<br/>
  # <br/>
  # attributes:<br/>
  # <pre>
  #   [R]  string: string to parse
  #   [RW] pos: current position
  #   [R]  source: source file name
  #   [RW] err: parsing error
  #   [R]  column: current position in line
  #   [R]  line: current line number
  #   [R]  current_line_text: current line text
  #   [R]  cache: for memoization
  # </pre>
  class ParseContext < StringScanner
    attr_reader :source, :cache
    attr_accessor :err
    def initialize str, source
      super(str)
      @source = source
      @cache = {}
    end
    
    def clear_cache
      @cache.clear
    end

    def line
      string[0...pos].count("\n") + 1
    end

    def column
      return 1 if pos == 0
      newline_pos = string.rindex "\n", pos - 1
      if newline_pos
        pos - newline_pos
      else
        pos + 1
      end    
    end
    alias col column

    def current_line_text
      from = string.rindex "\n", pos - 1
      to = string.index "\n", pos
      string[(from || 0)..(to || -1)]
    end
  end

  # the skip token
  SKIP = Object.new
  class << SKIP
    # check if x is skip token
    def [] x
      self == x
    end
    def to_str
      'SKIP_TOKEN'
    end
    def inspect
      'SKIP_TOKEN'
    end
  end

  # the invalid token
  INVALID = Object.new
  class << INVALID
    def [] x
      self == x
    end
    def to_str
      'INVALID_TOKEN'
    end
    def inspect
      'INVALID_TOKEN'
    end
  end

  attr_accessor :name
  def inspect
    # TODO move
    @name ||= self.class.to_s[/\w+$/]
    case self
    when Lazy, Dynamic
      "<#{name}>"
    when Binary
      "<#{name} #{left.inspect} #{right.inspect}>"
    when Unary
      "<#{name} #{some.inspect}>"
    when Array
      # don't use redefined map!
      res = []
      each{|e| res << e.inspect}
      "<#{name} #{res.join ' '}>"
    else
      "<#{name}>"
    end
  end

  # error class for rescue
  class ParseError < StandardError
    attr_reader :ctx, :msg

    # beautiful constructor
    def self.[] msg, ctx
      self.new msg, ctx
    end

    # constructor
    def initialize msg, ctx
      @msg, @ctx = msg, ctx
    end

    # info with source position
    def to_s
      # TODO show last parser
      coord = "\"#{@ctx.source}\": (#{@ctx.line}, #{@ctx.col})"
      "[#{@msg}] in #{coord}\n#{@ctx.current_line_text[0..79]}\n#{' ' * @ctx.col}^"
    end
  end
end
