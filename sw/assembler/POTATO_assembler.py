#!/usr/bin/python3
# Python script to convert a very basic asm to a binary file that can be loaded
# into the uPOTATO core
# 2023-01-09
# Andrew Smith
# Currently only supports RV32I Base Instruction Set

import sys
import os
import ply.lex as lex
import ply.yacc as yacc

# [label] mnemonic [operands] [;comment]

tokens = (
    'PSOP_TEXT',
    'PSOP_RODATA',
    'PSOP_DATA',
    'PSOP_BSS',
    'PSOP_STRING',
    'LABEL',
    'LUI',
    'AUIPC',
    'JAL',
    'JALR',
    'BEQ',
    'BNE',
    'BLT',
    'BGE',
    'BLTU',
    'BGEU',
    'LB',
    'LH',
    'LW',
    'LBU',
    'LHU',
    'SB',
    'SH',
    'SW',
    'ADDI',
    'SLTI',
    'SLTIU',
    'XORI',
    'ORI',
    'ANDI',
    'SLLI',
    'SRLI',
    'SRAI',
    'ADD',
    'SUB',
    'SLL',
    'SLT',
    'SLTU',
    'XOR',
    'SRL',
    'SRA',
    'OR',
    'AND',
    'FENCE',
    'FENCEI',
    'ECALL',
    'EBREAK',
    'CSRRW',
    'CSRRS',
    'CSRRC',
    'CSRRWI',
    'CSRRSI',
    'CSRRCI',
    'COMMA',
    'NUMBER',
    #  'HEX_NUMBER', #TODO: Add for Byte, 2Byte(Half,Short), Word(Long), 8Byte(Dword,Quad)
    'LPAREN',
    'RPAREN',
    'X0',
    'X1',
    'X2',
    'X3',
    'X4',
    'X5',
    'X6',
    'X7',
    'X8',
    'X9',
    'X10',
    'X11',
    'X12',
    'X13',
    'X14',
    'X15',
    'X16',
    'X17',
    'X18',
    'X19',
    'X20',
    'X21',
    'X22',
    'X23',
    'X24',
    'X25',
    'X26',
    'X27',
    'X28',
    'X29',
    'X30',
    'X31',
    'OLABEL',
    'RETURN',
    'COMMENT')

# Regex for tokens:
t_PSOP_TEXT = r'\.text'
t_PSOP_RODATA = r'\.rodata'
t_PSOP_DATA = r'\.data'
t_PSOP_BSS = r'\.bss'
t_PSOP_STRING = r'\.string'
t_LABEL = r'[A-Za-z_0-9]+:'
t_LUI = r'(LUI|lui)'
t_AUIPC = r'(AUIPC|auipc)'
t_JAL = r'(JAL|jal)'
t_JALR = r'(JALR|jalr)'
t_BEQ = r'(BEQ|beq)'
t_BNE = r'(BNE|bne)'
t_BLT = r'(BLT|blt)'
t_BGE = r'(BGE|bge)'
t_BLTU = r'(BLTU|bltu)'
t_BGEU = r'(BGEU|bgeu)'
t_LB = r'(LB|lb)'
t_LH = r'(LH|lh)'
t_LW = r'(LW|lw)'
t_LBU = r'(LBU|lbu)'
t_LHU = r'(LHU|lhu)'
t_SB = r'(SB|sb)'
t_SH = r'(SH|sh)'
t_SW = r'(SW|sw)'
t_ADDI = r'(ADDI|addi)'
t_SLTI = r'(SLTI|slti)'
t_SLTIU = r'(SLTIU|sltiu)'
t_XORI = r'(XORI|xori)'
t_ORI = r'(ORI|ori)'
t_ANDI = r'(ANDI|andi)'
t_SLLI = r'(SLLI|slli)'
t_SRLI = r'(SRLI|srli)'
t_SRAI = r'(SRAI|srai)'
t_ADD = r'(ADD|add)'
t_SUB = r'(SUB|sub)'
t_SLL = r'(SLL|sll)'
t_SLT = r'(SLT|slt)'
t_SLTU = r'(SLTU|sltu)'
t_XOR = r'(XOR|xor)'
t_SRL = r'(SRL|srl)'
t_SRA = r'(SRA|sra)'
t_OR = r'(OR|or)'
t_AND = r'(AND|and)'
t_FENCE = r'(FENCE|fence)'
t_FENCEI = r'(FENCEI|fencei)'
t_ECALL = r'(ECALL|ecall)'
t_EBREAK = r'(EBREAK|ebreak)'
t_CSRRW = r'(CSRRW|csrrw)'
t_CSRRS = r'(CSRRS|csrrs)'
t_CSRRC = r'(CSRRC|csrrc)'
t_CSRRWI = r'(CSRRWI|csrrwi)'
t_CSRRSI = r'(CSRRSI|csrrsi)'
t_CSRRCI = r'(CSRRCI|csrrci)'
t_COMMA = r','
#t_NUMBER = r'-?[0-9]+'
#t_HEX_NUMBER = r'0x[0-9]+'
t_LPAREN = r'\('
t_RPAREN = r'\)'
t_X0 = r'(X0|x0|ZERO|zero)'
t_X1 = r'(X1|x1|RA|ra)'
t_X2 = r'(X2|x2|SP|sp)'
t_X3 = r'(X3|x3|GP|gp)'
t_X4 = r'(X4|x4|TP|tp)'
t_X5 = r'(X5|x5|T0|t0)'
t_X6 = r'(X6|x6|T1|t1)'
t_X7 = r'(X7|x7|T2|t2)'
t_X8 = r'(X8|x8|S0|s0|FP|fp)'
t_X9 = r'(X9|x9|S1|s1)'
t_X10 = r'(X10|x10|A0|a0)'
t_X11 = r'(X11|x11|A1|a1)'
t_X12 = r'(X12|x12|A2|a2)'
t_X13 = r'(X13|x13|A3|a3)'
t_X14 = r'(X14|x14|A4|a4)'
t_X15 = r'(X15|x15|A5|a5)'
t_X16 = r'(X16|x16|A6|a6)'
t_X17 = r'(X17|x17|A7|a7)'
t_X18 = r'(X18|x18|S2|s2)'
t_X19 = r'(X19|x19|S3|s3)'
t_X20 = r'(X20|x20|S4|s4)'
t_X21 = r'(X21|x21|S5|s5)'
t_X22 = r'(X22|x22|S6|s6)'
t_X23 = r'(X23|x23|S7|s7)'
t_X24 = r'(X24|x24|S8|s8)'
t_X25 = r'(X25|x25|S9|s9)'
t_X26 = r'(X26|x26|S10|s10)'
t_X27 = r'(X27|x27|S11|s11)'
t_X28 = r'(X28|x28|T3|t3)'
t_X29 = r'(X29|x29|T4|t4)'
t_X30 = r'(X30|x30|T5|t5)'
t_X31 = r'(X31|x31|T6|t6)'
t_OLABEL = r'[A-Za-z_0-9]+:'
t_RETURN = r'ret'
t_ignore_COMMENT = r'(\#|;).*'


def t_NUMBER(t):
    r'-?\d+'
    try:
        t.value = int(t.value)
    except:
        print("ERROR in parsing integer %d", t.value)
        t.value = 0
    return t


# NewLine rule:
def t_newline(t):
    r'\n+'
    t.lexer.lineno += len(t.value)


t_ignore = ' \t'


# Error handling rule
def t_error(t):
    print("Illegal character '%s'" % t.value[0])
    t.lexer.skip(1)


# Byte Array
binary = []
address = 0x4000  # start address of program
current_section = "none"

# Build the lexer
lexer = lex.lex()


def d_statement_addi(t):
    'statement : ADDI COMMA '
    print(t[1])


data = '''
  .data

  .text
  main:                                   # @main
        addi    sp, sp, -16
        sw      ra, 12(sp)                      # 4-byte Folded Spill
        sw      s0, 8(sp)                       # 4-byte Folded Spill
        addi    s0, sp, 16
        andi    a1, a1, 0
        sw      a1, -12(s0)
        sw      a0, -16(s0)
        lw      a0, -16(s0)
        addi    a0, a0, 1
        lw      ra, 12(sp)                      # 4-byte Folded Reload
        lw      s0, 8(sp)                       # 4-byte Folded Reload
        addi    sp, sp, 16
        ret'''

# Give the lexer some input
lexer.input(data)

# Tokenize
while True:
    tok = lexer.token()
    if not tok:
        break  # No more input
    print(tok)
