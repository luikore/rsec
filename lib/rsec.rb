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

  VERSION = '0.4'
end

require "strscan"
require "rsec/utils"
require "rsec/parser"
require "rsec/helpers"
