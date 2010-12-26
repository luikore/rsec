# coding: utf-8

# grammar from
#   http://www.json.org/

require "rsec"

class SlowJSON

  include Rsec::Helper

  def initialize
    generate_parser
    @parser = (/\s*/.r >> @value << /\s*/).eof
  end

  def parse s
    @parser.parse! s
  end

  private

  # term (, term)*
  def elem_parser term
    /\s*/.r >> term.join(/\s*,\s*/.r.skip) << /\s*/
  end

  def chars_parser
    unicode_bytes = /[0-9a-f]{4}/i.r.map{|bytes|
      [bytes].pack('H*').force_encoding('utf-16be').encode!('utf-8')
    }
    escape_char = '"'.r | "\\".r | '/'.r |
                  'b'.r >> value("\b") |
                  'f'.r >> value("\f") |
                  'n'.r >> value("\n") |
                  'r'.r >> value("\r") |
                  't'.r >> value("\t") |
                  'u'.r >> unicode_bytes
    /[^"\\]+/.r | '\\'.r >> escape_char
  end

  def generate_parser
    string  = '"'.r >> (chars_parser ** 0).map(&:join) << '"'
    # -? int frac? exp?
    number  = /-?
               (?:[1-9]\d*|0)
               (?:\.\d+)?
               (?:[eE][+-]?\d+)?
              /x.r.map &:to_f
    @value  = string | number | lazy{@object} | lazy{@array} |
              'true'.r  >> value(true) |
              'false'.r >> value(false) |
              'null'.r  >> value(nil)
    pair    = [string, /\s*:\s*/.r.skip, @value].r
    @array  = /\[\s*\]/.r >> value([]) |
              '['.r >> elem_parser(@value) << ']'
    @object = /\{\s*\}/.r >> value({}) |
              '{'.r >> elem_parser(pair).map{|arr|Hash[arr]} << '}'
  end

end

if __FILE__ == $PROGRAM_NAME
  j = SlowJSON.new
  p j.parse '""'
  p j.parse '123.4e5'
  p j.parse 'null'
  p j.parse '[]'
  p j.parse '{}'
  p j.parse '{"no": [3, 4]}'
  p j.parse '[{}]'
  p j.parse '[{"S":321061,"T":"GetAttributeResp"},{"ERROR":null,"TS":0,"VAL":{"SqlList":[{"BatchSizeMax":0,"BatchSizeTotal":0,"ConcurrentMax":1,"DataSource":"jdbc:wrap-jdbc:filters=default,encoding:name=ds-offer:jdbc:mysql://100.10.10.10:8066/xxxx","EffectedRowCount":0,"ErrorCount":0,"ExecuteCount":5,"FetchRowCount":5,"File":null,"ID":2001,"LastError":null,"LastTime":1292742908178,"MaxTimespan":16,"MaxTimespanOccurTime":1292742668191,"Name":null,"RunningCount":0,"SQL":"SELECT @@SQL_MODE","TotalTime":83}]}}]'
end

