# coding: utf-8
# load the gem

# All code is under this module
module Rsec
  # preload configs
  
  # config method name
  # default is :r
  unless Rsec.const_defined?(:TO_PARSER_METHOD)
    TO_PARSER_METHOD = :r
  end

  # config use C extension strategy
  # options:
  #   :try - default
  #   :no
  #   :yes
  unless Rsec.const_defined?(:USE_CEXT)
    USE_CEXT = :try
  end

  VERSION = '0.1'
end

require "strscan"
require "rsec/base"
require "rsec/unary"
require "rsec/binary"
require "rsec/xnary"
require "rsec/helpers"

case Rsec::USE_CEXT
when :try
  require "rsec/ext" rescue nil
when :yes
  require "rsec/ext"
when :no
else
  warn "Rsec::USE_CEXT should be one of :try, :yes, :no"
end

