# a markdown translator
# 
# The differences between this and original markdown:
# - markdown in inline tags are not processed
# - every line-break in non-tag parts is translated into <br/>
# - nested list elements are not supported

require "rsec"

class LittleMarkdown
  include Rsec::Helper

  def initialize
    @markdown_line_translator = make_markdown_line_translator
    @parser = (make_xml_tag_parser | make_char_parser).star.eof
  end

  def translate src
    @stack = []
    @charsbuf = ''
    @out = ''
    @parser.parse! src
    flush_chars
    @out
  end

  def flush_chars
    @out.<< translate_markdown @charsbuf
    @charsbuf = ''
  end

  def make_char_parser
    # care stringscanner's bug, see issues
    (/./.r | /\n/).fail('char'){|c| @charsbuf << c}
  end

  # make a single-line markdown parser
  def make_markdown_line_translator
    line_text = lazy{line}.map{|tokens|
      tokens.empty? ? Rsec::INVALID : tokens.join # filter out empty
    }

    title = /"[^"]*"|'[^']*'/.r._?{|(s)|
      s ? "title=#{s}" : ''
    }
    img = seq('!['.r >> /[^\]]+/ << '](', /[^\)"']+/, title, ')'){|(txt, path, title)|
      "<img src='#{path}' #{title}>#{txt}</img>"
    }
    link = seq(('['.r >> /[^\]]+/ << ']('), /[^\)"']+/, title, ')'){|(txt, path, title)|
      "<a href='#{path}' #{title}>#{txt}</a>"
    }
    # NOTE strong should be left of em
    strong = ('**'.r >> line_text << '**').map{|s|
      "<strong>#{s}</strong>"
    }
    em = ('*'.r >> line_text << '*').map{|s|
      "<em>#{s}</em>"
    }
    code = ('`'.r >> /[^`]+/ << '`').map{|s|
      "<code>#{s}</code>"
    }
    escape = '<'.r{'&lt;'} | '&'.r{'&amp;'} | /\\[\!\`\*\[\]]/.r{|s|s[1]}
    text = /[^\!\`\*\[\]]+/
    id = seq_(('['.r >> /[^\]]+/ << ']:'), text){|(id, text)|
      "<span id='#{id}'>#{text}</span>"
    }
    line = (img | link | strong | em | code | escape | id | text).star
    line.eof.map &:join
  end
  
  # pseudo xml tag parser, except <br> and <hr> and <script>
  def make_xml_tag_parser
    name  = /[\w-]+/ # greedy, no need to worry space between first attr
    value = /"[^"]*"|'[^']*'/
    attr  = seq_(name, seq_('=', value)._?)
    attrs = /\s*/.r.join(attr)

    # use a stack to ensure tag matching
    tag_start = seq('<', name, attrs){|res|
      @stack.push res[1].downcase
      res
    }
    tag_empty_end = '/>'.r{|res|
      @stack.pop
      res
    }
    tag_non_empty_end = seq('>', lazy{content}, '</', name, /\s*\>/){|res|
      if @stack.pop == res[3].downcase
        res
      else
        Rsec::INVALID
      end
    }
    special_tag = /\<[bh]r\s*\>/i.r | seq_('<script', attrs, /\>.*?\<\/script\>/)
    tag = special_tag | seq(tag_start, (tag_empty_end | tag_non_empty_end))

    # xml content
    comment = /<!--([^-]|-[^-])*-->/
    cdata   = /<!\[CDATA\[.*?\]\]>/x
    entity  = /&(nbsp|lt|gt|amp|cent|pound|yen|euro|sect|copy|reg|trade|#[a-f0-9]{2,4});/i
    text    = /[^<&]+/
    content = (cdata.r | comment | entity | tag | text).star
    tag.fail('tag'){|res|
      if @charsbuf.end_with? "\n"
        flush_chars
        @out << res.join
      else
        @charsbuf << res.join # inline tags
      end
    }
  end

  # translate markdown
  def translate_markdown str
    lines = str.split("\n").chunk{|line|
      line[/^(\ {4}|\#{1,6}\ |[\+\-\>]\ |)/]
    }.map{|(leading, lines)|
      case leading
      when '    '                                              # code
        "<pre><code>#{lines.join "\n"}</code></pre>"
      when /\#{1,6}/                                           # headings
        hn = "h#{leading.strip.size}"
        lines.map! do |line|
          line = line.sub(/\#{1,6}/, '')
          "<#{hn}>#{@markdown_line_translator.parse! line}</#{hn}>"
        end
        lines.join
      when '> '                                                # block quote
        # TODO nested
        lines.map! do |line|
          @markdown_line_translator.parse! line[2..-1]
        end
        "<blockquote>#{lines.join '<br/>'}</blockquote>"
      when '+ '                                                # numbered list
        # TODO nested
        lines.map! do |line|
          "<li>#{@markdown_line_translator.parse! line[2..-1]}</li>"
        end
        "<ol>#{lines.join}</ol>"
      when '- '                                                # unordered list
        # TODO nested
        lines.map! do |line|
          "<li>#{@markdown_line_translator.parse! line[2..-1]}</li>"
        end
        "<ul>#{lines.join}</ul>"
      else
        lines.map! do |line|
          @markdown_line_translator.parse! line
        end
        lines.join "<br/>"
      end
    }
    # add trailing '\n' s
    lines.join('<br/>') << ('<br/>' * str[/\n*\Z/].size)
  end

end

if __FILE__ == $PROGRAM_NAME
  lm = LittleMarkdown.new
  puts lm.translate <<-MD
## *a *
<pre a="3">123afd</pre>
  ** b **
  MD
end

