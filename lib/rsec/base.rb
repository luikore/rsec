# coding: utf-8
# ------------------------------------------------------------------------------
# Parser Base

module Rsec
  # whole parse<br/>
  # returns nil if unparsed or not str terminated after parsing
  def parse str, source_name='source'
    ctx = ParseContext.new str, source_name
    ret = _parse ctx
    if ctx.eos?
      ret
    end
  end

  # almost the same as parse<br/>
  # but raises ParseError
  def parse! str, source_name='source'
    ctx = ParseContext.new str, source_name
    ret = _parse ctx
    unless ret
      raise ParseError[ctx.err || 'syntax error', ctx]
    end
    unless ctx.eos?
      raise ParseError['parse terminated before end of input', ctx]
    end
    ret
  end

  # partly parse the string, returns [parse_result, rest]
  def partial_parse str, source_name='source'
    ctx = ParseContext.new str, source_name
    ret = _parse ctx
    [ret, ctx.rest]
  end

  # TODO
  # continuous parsing

  # right assoc node
  # TODO make it c-extension of binary tree
  class RAssocNode < Array
    def assoc e
      return self if e == :_skip_
      if size() < 2
        @last_ary = self # save push position
        return push(e)
      end
      @last_ary[-1] = RAssocNode[@last_ary[-1], e]
      @last_ary = @last_ary[-1]
      self
    end
  end

  # left assoc node
  class LAssocNode < Array
    def assoc e
      return self if e == :_skip_
      push e
      # e.is_a?(LAssocNode) ? concat(e) : push(e)
    end
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

  # error class for catching
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
      coord = "\"#{@ctx.source}\": (#{@ctx.line}, #{@ctx.col})"
      "[#{@msg}] in #{coord}\n#{@ctx.current_line_text[0..79]}\n#{' ' * @ctx.col}^"
    end
  end
end
