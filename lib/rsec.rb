# coding: utf-8
# ------------------------------------------------------------------------------
# Parser Base

require "strscan"
Dir.glob "#{File.dirname __FILE__}/rsec/*.rb" do |f|
  require f
end

module Rsec
  # global parse, calls _parse<br/>
  # all _parse should take a param (instance of StringScanner) and a block<br/>
  # the block's first argument is the parse result<br/>
  # if the content in block evals nil/false, _parse fails and try to go back.<br/>
  # when the trace becomes empty, then all failed.
  def parse str, source_name='source'
    parse! str, source_name
  rescue ParseError => e
    # report error
    puts e, e.backtrace
  end

  # almost the same as parse<br/>
  # but raises ParserError
  def parse! str, source_name='source'
    ctx = ParseContext.new str, source_name
    ret = _parse ctx
    unless ret
      raise ParseError[ctx.err || 'syntax error', ctx]
    end
    unless ctx.eos?
      raise ParseError['no more can be parsed', ctx]
    end
    ret
  end

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
      e.is_a?(LAssocNode) ? concat(e) : push(e)
    end
  end

  # parse context<br/>
  # attributes:<br/>
  # <pre>
  #   [R ] string: string to parse
  #   [RW] pos: current position
  #   [R ] source: source file name
  #   [RW] err: parsing error
  # </pre>
  class ParseContext < StringScanner
    attr_reader :source
    attr_accessor :err
    def initialize str, source
      super(str)
      @source = source
    end
  end

  # error class for catching
  class ParseError < StandardError
    attr_accessor :ctx, :msg

    # beautiful constructor
    def self.[] msg, ctx
      self.new msg, ctx
    end

    # constructor
    def initialize msg, ctx
      @msg, @ctx = msg, ctx
    end

    # message helper to point out source position
    def to_s
      pos = @ctx.pos
      str = @ctx.string
      line = line_of str, pos
      col = col_of str, pos
      coord = "\"#{@ctx.source}\": (#{line}, #{col})"
      start = pos > 30 ? (pos - 30) : 0
      "[#{@msg}] in #{coord}\n#{str.slice start, 60}\n#{' ' * (pos - start)}^"
    end

    # helper: column of pos in str
    def col_of str, pos
      return 1 if pos == 0
      newline_pos = str.rindex "\n", pos - 1
      if newline_pos
        pos - newline_pos
      else
        pos + 1
      end
    end
    
    # helper: line of pos in str
    def line_of str, pos
      str[0...pos].count("\n") + 1
    end
  end
end
