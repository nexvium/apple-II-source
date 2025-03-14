" Vim syntax file for Apple II assembly programs.
"
" NOTE: Incomplete...

syntax match LineComment    /^\s*\*.*$/
syntax match EndComment     /;.*$/

syntax match GlobalLabel    /\%([A-Z][A-Z0-9_]\+\)/
syntax match LocalLabel     /:[A-Z0-9_]\+/

syntax match MemoryAddress  /\$[0-9A-F]\+/
syntax match Immediate      /#\(\(\$[0-9A-F]\+\)\|\([0-9]\+\)\|\(["'].["']\)\)/
syntax match Bytes          /[0-9A-F]\+\(,[0-9A-F]\+\)\+/

syntax region String start=#\s*\(["']\)# end=#\s*\(["']\)#

syntax keyword Mos6502Instruction ADC AND ASL BBR BBS BCC BCS BEQ BIT BMI BNE
            \ BPL BRA BRK BVC BVS CLC CLD CLI CLV CMP CPX CPY DEA DEC DEX DEY
            \ EOR INA INC INX INY JMP JSR LDA LDX LDY LSR NOP ORA PHA PHP PHX
            \ PHY PLA PLP PLX PLY RMB ROL ROR RTI RTS SBC SEC SED SEI SMB STA
            \ STX STY STZ TAX TAY TRB TSB TSX TXA TXS TYA

syntax keyword AssemblerDirective ASC DA DFB EQU HEX ORG STR

highlight LineComment cterm=italic ctermfg=gray gui=italic guifg=lightgray
highlight EndComment cterm=italic ctermfg=gray gui=italic guifg=lightgray

highlight Mos6502Instruction cterm=bold ctermfg=cyan gui=bold guifg=lightblue
highlight AssemblerDirective cterm=italic ctermfg=cyan gui=italic guifg=lightblue

highlight GlobalLabel guifg=lightgreen
highlight LocalLabel gui=italic guifg=lightgreen

highlight MemoryAddress guifg=lightred
highlight String        guifg=lightmagenta
highlight Immediate     guifg=lightmagenta
highlight Bytes         guifg=lightmagenta

" eof
