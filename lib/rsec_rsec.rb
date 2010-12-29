require "strscan"

# configure method name
module Rsec
  unless Rsec.const_defined?(:TO_PARSER_METHOD)
    TO_PARSER_METHOD = :rsec
  end
end

# require all
require "rsec/base"
require "rsec/unary"
require "rsec/binary"
require "rsec/xnary"
require "rsec/helpers"

if File.exist?("#{File.dirname(__FILE__)}/../ext/rsec/predef.so")
  require "rsec/ext"
  require "rsec/predef"
end

