# Parse NASM manual [nasm.txt] and generate a list of opcodes.
# Results are saved in [nasm_codes.txt], undocumented codes are printed.
# Further: extend the parser to generate an X86 assembler.
require "rsec"

module NASMManualParser
  include Rsec::Helper
  extend self

  Instructions = {}

  class UnSupportedError < RuntimeError
  end

  class Instruction < Struct.new(:nemonic, :operands, :code, :archs)
  end

  def debug parser, *strs
    return parser unless $debug
    strs.each do |str|
      parser.eof.parse! str
    end
    parser
  end

  def reg_parser
    gp_reg  = /E?[ABCD]X|E?(SP|BP|SI|DI)/
    gp_reg8 = /[ABCD][HL]/
    seg_reg = /ES|CS|SS|DS|FS|GS/
    fpu_reg = /ST[0-7]/
    mmx_reg = /MM[0-7]/
    xr_reg  = /CR[0234]|DR[012367]|TR[34567]/
    reg = gp_reg.r | gp_reg8 | seg_reg | fpu_reg | mmx_reg | xr_reg
    debug reg, 'AX'
  end

  def operands_parser
    imm_class     = /imm:imm(32|16)|imm(32|16|8)?/
    mem_class     = /mem(80|64|32|16|8)?/ # be ware of the order
    reg_class     = /reg(32|16|8)|(fpu|mmx|seg)reg/
    memoffs_class = /memoffs(32|16|8)/
    tr_class      = 'TR3/4/5/6/7'
    classes       = (imm_class.r | memoffs_class | mem_class | reg_class | tr_class).fail 'operand class'
    reg           = reg_parser.fail 'register'
    num           = /\d/.r(&:to_i).fail 'num'
    # memoffs should be left of mem
    operand       = classes | reg | num
    operands      = operand.join('/').even.join(',').even
    debug operands, 'reg32', 'AX,memoffs16'
  end

  def code_parser
    plus_cc     = /[0-9A-F][0-9A-F]\+cc/
    plus_r      = /[0-9A-F][0-9A-F]\+r/
    hex         = /[0-9A-F][0-9A-F]/.r {|s| s.to_i 16}
    slash       = /\/[\dr]/
    imm_code    = /i[bwd]/
    reg_code    = /rw\/rd|r[bwd]/
    ref_code    = /ow\/od|o[wd]/
    prefix_code = /[oa](32|16)/
    code =\
      (plus_cc.r | plus_r | hex | slash |
      imm_code | reg_code | ref_code | prefix_code).join(/\s+/).even
    debug code, 'o32 0F C8+r', 'o32 6B /r ib', 'o16 A1 ow/od'
  end

  def archs_parser
    arch = symbol(/8086|186|286|386|486|PENT|P6|CYRIX|FPU|MMX|PRIV|UNDOC/)
    archs = ('['.r >> arch.join(',').even << ']').map do |archs|
      # map to set
      archs.inject({}){|h, arch|
        raise UnSupportedError, 'not implemented' if arch == 'UNDOC'
        h[arch] = true
        h
      }
    end
    debug archs, '[386,FPU]'
  end

  def instruction_parser
    nemonic = /[A-Z]\w+|xxSAR/
    operands = operands_parser._?
    code = ';'.r >> code_parser
    archs = archs_parser
    instruction = seq_ nemonic, operands, code, archs do |nemonic, (operands), code, archs|
      Instruction.new nemonic, operands, code, archs
    end
    debug instruction, 'FISUBR mem32 ; DA /5 [8086,FPU]', 'BSWAP reg32 ; o32 0F C8+r [486]'
  end

  def desugar line
    # r/m short hands
    line = line.gsub /r\/m(32|16|8)/, 'reg\1/mem\1'
    line.gsub! 'r/m64', 'mmxreg/mem64'
    # compress space
    line.sub! /\s(TO|NEAR|FAR|SHORT)/, '_\1'
    line
  end

  def parse_line parser, line
    parser.parse! desugar line
  rescue Rsec::SyntaxError
  rescue UnSupportedError
  end

  def parse filename
    parsed = ''
    parser = instruction_parser.eof
    src = File.read filename
    src.lines.with_index do |raw_line, idx|
      line = raw_line.strip
      # this shapy shows the line is something defining an nemonic
      if line =~ /^\w+\s+[^;\[]+;\ [^;\[]+\[.+\]$/
        if (parse_line parser, line)
          parsed << raw_line
        else
          puts "unparsed:#{idx}\t#{line}"
        end
      end
    end
    parsed
  end

end

if __FILE__ == $PROGRAM_NAME
  $debug = true
  manual = "#{File.dirname __FILE__}/nasm_manual.txt"
  codes  = "#{File.dirname __FILE__}/nasm_codes.txt"
  File.open codes, 'w' do |file|
    file.<< NASMManualParser.parse manual
  end
  puts '-' * 80
  puts "X86 asm codes are saved to #{codes}"
end

