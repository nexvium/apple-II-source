* Assembler Pro
* By Javier Alvarado
* Copyright (C) 1991
* Quantum

         ORG $800

TEMP     EQU $00        ;Temporary storage
TEMP2    EQU $02        ;Temporary storage
POSPTR   EQU $04        ;Position pointer
ENDPTR   EQU $06        ;End of listing pointer
TOPSCR   EQU $08        ;Top of screen display
ENTRYFLG EQU $19        ;Is input for listing?
CH       EQU $24        ;Horizontal cursor position
TIMER    EQU $4E        ;Cursor timer
INBUFF   EQU $200       ;Input buffer
BUFFPOS  EQU $300       ;Position in buffer
MODE     EQU $301       ;Insert/overstrike cursor
CUR_CHAR EQU $302       ;Display cursor/character
SVKEY    EQU $303       ;Saved key
LENGTH   EQU $304       ;Length of input
MAXLEN   EQU $305       ;Maximum length of input
SCRLINE  EQU $306       ;Screen line number
LINELEN  EQU $307       ;Length of old line
LINENUM  EQU $308       ;Line number
CHANGED  EQU $30A       ;Line changed flag
KEYBOARD EQU $C000      ;Keyboard location
STROBE   EQU $C010      ;Keyboard strobe location
SPEAKER  EQU $C030      ;Speaker address
OPN_APL  EQU $C061      ;Open-Apple flag
CLSD_APL EQU $C062      ;Closed-Apple flag
LINPRT   EQU $ED24      ;Print decimal number
TABV     EQU $FB5B      ;VTAB cursor
CLREOP   EQU $FC42      ;Clear to end of page
HOME     EQU $FC58      ;Clear screen
CLREOL   EQU $FC9C      ;Clear to end of line
WAIT     EQU $FCA8      ;Monitor wait routine
CROUT    EQU $FD8E      ;Print a carriage return
COUT     EQU $FDED      ;Print a character

         STZ $3F4       ;Boot on Ctrl-Reset
HANG     JMP HANG       ;Lock up the computer

*======================================
* INITIALIZE:
*======================================

TOP_FILE LDX #$00       ;Set pointers to $2000
         LDA #$20
         STX POSPTR
         STA POSPTR+1
         STX TOPSCR
         STA TOPSCR+1
         BIT BUFFPOS    ;Is this the first time?
         BPL :1         ;No, so skip this
         STX ENDPTR
         STA ENDPTR+1
         LDA #$FF       ;Mark the end of the file
         STA (ENDPTR)
:1       LDA #$01       ;Set line 1
         STA LINENUM
         STZ LINENUM+1
         LDA #$02
         STA SCRLINE    ;Top of screen
         STZ ENTRYFLG   ;Set input to entry
         STZ INBUFF     ;Mark end of input
         STZ BUFFPOS    ;Mark position in buffer

*======================================
* MAIN PROGRAM:
*======================================

*--------------------------------------
* Reprint Screen:
*--------------------------------------
FIXSCR   LDA #$02       ;Move to top of screen
         JSR TABV
         LDX TOPSCR     ;Copy top of screen pointer
         LDA TOPSCR+1   ;to print pointer
         STX TEMP
         STA TEMP+1
         LDX #$00       ;Clear line counter
:1       JSR PRT_LINE   ;Print a line of listing
         BCS :2
         INX            ;Increment line counter
         CPX #20        ;Have we printed 20 lines?
         BEQ :2         ;Yes, we're done printing
         JSR CROUT      ;Print carriage return
         JSR NXT_LINE   ;Find  address on next line
         BRA :1         ;Go do next line
:2       JSR BOTTOM     ;Move to bottom line
         LDA #67
         STA CH         ;Move to other side of screen
         LDA #"A"       ;MouseText Open-Apple
         JSR MOUSEOUT   ;Print it
         JSR PRINT      ;Print the rest of the message
         ASC "-? for help",00
NEXT     LDA SCRLINE
         JSR TABV
         STZ CH
         STZ INBUFF     ;Set end of line
         LDY #$00       ;Clear index
:1       LDA (POSPTR),Y ;Get character from memory
         CMP #$FF       ;Is it end of file marker?
         BEQ :2         ;Yes, we're done
         STA INBUFF,Y   ;Put the char in the buffer
         CMP #$00       ;Is it end of line marker?
         BEQ :2         ;Yes, we're done
         JSR COUT
         INY            ;Prepare for next
         BRA :1         ;Go do the next one
:2       PHA
         PHY
         JSR CLREOL     ;Clear the rest of the line
         PLY
         PLA
         STY LENGTH     ;Set length of line
         CPY BUFFPOS
         BCS :2A
         STY BUFFPOS
:2A      CMP #$FF
         BEQ :3
         INY
:3       STY LINELEN
         STZ CHANGED    ;Signal no change
         CLC

*--------------------------------------
* Get User Input:
*--------------------------------------
GET_INP  LDX #60        ;Maximum length
         JSR GET_LINE   ;Go get a line of data
         BCS DO_CMD     ;If no error, go save line
         JSR FIX_LINE
         JSR STORE      ;Move line to memory
         JSR INSRTLIN   ;Insert line
         JSR MV_DOWN    ;Move down a line
         JMP NEXT       ;Go do it again
DO_CMD   BVS APL_CMD    ;Go handle Apple command
         CMP #$89       ;Was it [Tab]?
         BEQ :DO_TAB    ;Yes, go handle it
         CMP #$8A       ;Was it down arrow?
         BEQ :DO_DOWN
         CMP #$8B       ;Was it up arrow?
         BEQ :DO_UP
         JMP GET_INP    ;Not a command
:DO_TAB  JMP TAB        ;Go handle a tab
:DO_DOWN JMP DOWN_ARR   ;Go handle a down arrow
:DO_UP   JMP UP_ARR     ;Go handle an up arrow
APL_CMD  CLV
         BRA GET_INP
TAB      LDX BUFFPOS    ;Get current buffer position
         CPX #$1A       ;Are we at the last stop?
         BCS :1C        ;Yes, so exit
:1       LDA INBUFF,X   ;Get char from buffer
         BNE :1A
         LDA #$A0       ;Put a space instead of zero
         STA INBUFF,X
         STZ INBUFF+1,X ;Move the end
         INC LENGTH     ;Add it to the length
:1A      JSR COUT       ;Print it
         INX
         CPX #$09       ;Is it the first stop?
         BEQ :1B        ;Yes
         CPX #$0D       ;The second stop?
         BEQ :1B        ;Yes
         CPX #$1A       ;Third stop?
         BNE :1         ;No, try again
:1B      STX BUFFPOS    ;Set new position
:1C      CLC            ;Command reconized
         JMP GET_INP    ;Get next command
DOWN_ARR LDA (POSPTR)   ;Are we at the last line?
         CMP #$FF
         BEQ :2         ;Yes, so exit
         JSR FIX_LINE
         JSR STORE      ;Move line to memory
:1       JSR MV_DOWN    ;Move down a line
         LDA KEYBOARD   ;Check if arrow is still down
         BIT STROBE     ;Clear the strobe
         CMP #$8A
         BNE :1A
         LDX POSPTR
         LDA POSPTR+1
         STX TEMP
         STA TEMP+1
         JSR PRT_LINE   ;Print line
         JSR NXT_LINE   ;Find address on next line
         LDX TEMP
         LDA TEMP+1
         STX POSPTR
         STA POSPTR+1
         JSR PRINTLC
         BRA :1
:1A      JMP NEXT       ;Go do it again
:2       CLC            ;Signal key recognized
         JMP GET_INP    ;Get next command
UP_ARR   LDA LINENUM    ;Are we at the first line?
         DEC
         BNE :1         ;No
         LDA LINENUM+1
         BNE :1
:A       CLC            ;Signal recognized command
         JMP GET_INP    ;Get next command
:1       LDA (POSPTR)   ;Are we on the last line?
         CMP #$FF
         BNE :1A
         BIT LENGTH
         BEQ :1B
:1A      BIT CHANGED    ;Was the line changed?
         BEQ :1B        ;No, so don't save it
         JSR FIX_LINE
         LDX POSPTR
         LDA POSPTR+1
         PHX
         PHA
         JSR STORE      ;Move line to memory
         PLA
         PLX
         STX POSPTR
         STA POSPTR+1
:1B      LDA LINENUM    ;Decrement line number
         BNE :2
         DEC LINENUM+1
:2       DEC LINENUM
         SEC
         LDA POSPTR
         SBC #$02
         STA POSPTR
         BCS :2A
         DEC POSPTR+1
:2A      LDA (POSPTR)
         BEQ :3
         LDA POSPTR
         BNE :2B
         DEC POSPTR+1
:2B      DEC POSPTR
         BRA :2A
:3       INC POSPTR
         BNE :3A
         INC POSPTR+1
:3A      LDA SCRLINE    ;Get screen line number
         CMP #$02       ;Is is the top row?
         BEQ :4
         DEC SCRLINE    ;Move one line up
         BRA :4A
:4       LDX POSPTR
         LDA POSPTR+1
         STX TOPSCR
         STA TOPSCR+1
         LDA #$96       ;Ctrl-V move everything on
         JSR COUT       ;screen one line down
:4A      LDA KEYBOARD   ;Check if arrow is still down
         BIT STROBE
         CMP #$8B
         BNE :5A
         LDX POSPTR
         LDA POSPTR+1
         STX TEMP
         STA TEMP+1
         JSR PRT_LINE
         JSR PRINTLC
         LDA POSPTR     ;Are we on the first line?
         BNE :1B
         LDA POSPTR+1
         CMP #$20
         BNE :1B
:5A      JMP NEXT

*======================================
* SOUBROUTINES:
*======================================
CMD_RET  SEC            ;Signal unknow key
         RTS            ;Return with key in Acc
GET_LINE STX MAXLEN     ;Save maximum length
         BCC DO_FLASH   ;If no error, skip ahead
DO_SOUND BIT SPEAKER    ;Toggle the speaker
         LDA #$1B       ;Set length of wait (tone)
         JSR WAIT       ;and waste that much time
         BIT STROBE     ;Was the bad key released?
         BMI DO_SOUND   ;No, continue with the sound
DO_FLASH BIT ENTRYFLG   ;Are we in entry mode?
         BNE :1         ;No, so skip this
         JSR PRINTLC    ;Print line and column numbers
:1       JSR GET_KEY    ;Get a key
         LDA SVKEY      ;Restore key
         BIT OPN_APL    ;Check for Open-Apple
         BMI DO_APL     ;Go handle Apple command
         BIT CLSD_APL   ;Check for Closed-Apple
         BMI DO_APL     ;Go handle Apple command
         JMP DELETE     ;Check for next command
DO_APL   AND #$DF       ;Make sure it's upper case
         CMP #"E"       ;Was it OA-E?
         BNE :1         ;No, check next key
         LDA #$FF
         EOR MODE       ;Toggle the flag
         STA MODE       ;Save the result
         BRA DO_FLASH   ;Get next key
:1       CMP #"Y"       ;Was it OA-Y?
         BNE :2         ;No, check something else
         LDX BUFFPOS    ;Get the current position
         STZ INBUFF,X   ;Mark new end
         LDA LENGTH     ;Get the length
         SEC            ;Prepare for subtraction
         SBC BUFFPOS
         TAY            ;Move result to Y-reg
         PHY            ;Save result
         LDA #$A0       ;Space
:1A      DEY
         BMI :1B        ;We're done
         JSR COUT       ;Print a space
         BRA :1A        ;Go do it again
:1B      PLY            ;Restore result
         JSR BACKSPC    ;Go back to where we were
         LDA BUFFPOS    ;Get current position
         STA LENGTH     ;and save as new length
         LDA #$FF       ;Signal line has been changed
         STA CHANGED
         BRA DO_FLASH   ;Get next key
:2       CMP #$88       ;Was it OA- <--?
         BNE :3         ;No, check something else
         LDY BUFFPOS    ;Move to begginning of line
         JSR BACKSPC
         STZ BUFFPOS    ;Move to begginning of buffer
         BRA DO_FLASH   ;Get next key
:3       CMP #$95       ;Was it OA- -->?
         BNE :4         ;No, signal error
         LDY BUFFPOS    ;Get current position
:3A      LDA INBUFF,Y   ;Get character from buffer
         BEQ :3B        ;If zero, we're done
         JSR COUT       ;Print it
         INY
         BRA :3A        ;Do it again
:3B      STY BUFFPOS    ;Save the new position
         BRA DO_FLASH   ;Get next key
:4       BIT $FF58      ;Set overflow flag (Apple key)
         JMP CMD_RET    ;Return
DELETE   CMP #$FF       ;Is it [Delete]?
         BNE RETURN     ;No, check next key
         LDX BUFFPOS    ;Get the position in buffer
         BEQ :C         ;If it's zero, ignore it
         LDA #$88       ;Print a backspace
         JSR COUT
         LDY #$00       ;Clear counter
:A       LDA INBUFF,X   ;Get char at current position
         BEQ :B         ;If at end, delete char
         JSR COUT       ;Print character
         INY            ;Add one to counter
         STA INBUFF-1,X ;Move character back
         INX            ;Get next character
         BRA :A
:B       DEX            ;One character back
         DEC BUFFPOS
         STZ INBUFF,X   ;Remove keypress from buffer
         LDA #$A0
         JSR COUT
         LDA #$88
         JSR COUT
         DEC LENGTH
         JSR BACKSPC    ;Move back
         LDA #$FF
         STA CHANGED
:C       JMP DO_FLASH   ;Get next key
RETURN   CMP #$8D       ;Is it [Return]?
         BNE LEFTARR    ;No, go check another
         JSR FIX_LINE
         CLC            ;Signal no error
         RTS
LEFTARR  CMP #$88       ;Is it [<--]?
         BNE RIGHTARR   ;No, go check another
         LDX BUFFPOS    ;Check buffer position
         BEQ :2         ;If zero, ignore key
:1       LDA #$88       ;Print a backspace
         JSR COUT
         DEC BUFFPOS    ;Save new position
:2       JMP DO_FLASH   ;Go back
RIGHTARR CMP #$95       ;Is it [-->]?
         BNE SAVEKEY    ;No, check something else
         LDX BUFFPOS    ;Get index
         LDA INBUFF,X   ;Get chacter at current position
         BEQ :1         ;If on end, ignore key
         JSR COUT
         INC BUFFPOS    ;Move the cursor
:1       JMP DO_FLASH
SAVEKEY  LDA SVKEY      ;Restore key
         CMP #$A0       ;Is it control character
         BCS :OK        ;No continue
         CLV            ;Clear overflow (not-Apple)
         JMP CMD_RET    ;Unknown key
:NO_GOOD JMP DO_SOUND   ;Signal error
:GO_BACK JMP DO_FLASH   ;Go do next key
:OK      LDA LENGTH
         CMP MAXLEN     ;Is it maximum length already?
         BEQ :NO_GOOD   ;Ignore key
         LDA #$FF
         STA CHANGED
         BIT ENTRYFLG   ;Is this part of listing?
         BNE :1
         LDY INBUFF     ;Is line a comment?
         CPY #"*"
         BEQ :1
         LDX BUFFPOS    ;Is it comment part of line?
         CPX #$1A
         BCS :1
         CMP #"a"
         BCC :1
         CMP #"{"
         BCS :1
         AND #$DF
         STA SVKEY
:1       LDY #$FF       ;Initialize counter
         LDX BUFFPOS    ;Get position in buffer
         LDA MODE       ;Check for overstike cursor
         BNE :A
:LOOP    LDA SVKEY      ;Restore key
         BEQ :RETURN    ;If it's zero, go finish up
         JSR COUT       ;If it's not, print it
         INY            ;Add one to counter
         PHA            ;Save character
         LDA INBUFF,X   ;Load and save char at
         STA SVKEY      ;this position
         PLA            ;Restore character
         STA INBUFF,X   ;Save old char in new position
         INX            ;Get ready for next character
         BRA :LOOP      ;Repeat
:RETURN  INC BUFFPOS    ;Move one over
         STZ INBUFF,X   ;Mark new end
         JSR BACKSPC    ;Move back to where we were
         INC LENGTH     ;One more to the length
         BRA :GO_BACK   ;Do next key
:A       LDA INBUFF,X
         BNE :A1        ;If it's not on end go
         LDA SVKEY
         JSR COUT       ;Print the character
         STA INBUFF,X   ;If it is, save key
         INX
         INC BUFFPOS    ;Save new position
         STZ INBUFF,X   ;Mark new end
         INC LENGTH
         BRA :A2
:A1      LDA SVKEY      ;Restore character
         JSR COUT
         STA INBUFF,X
         INX
         INC BUFFPOS    ;Save new position
:A2      JMP :GO_BACK   ;Repeat
BACKSPC  LDA #$88       ;Backspace char
:1       DEY
         BMI :2         ;If minus, we're done
         JSR COUT       ;Print backspace
         BRA :1         ;Do next
:2       RTS            ;Return
GET_KEY  LDA #$01       ;Make sure to print cursor
         STA TIMER      ;first when routine
         STA TIMER+1    ;is called
         STZ CUR_CHAR
         STZ STROBE
GETKEY   DEC TIMER
         BNE :1
         DEC TIMER+1
         BEQ FLASH
:1       BIT KEYBOARD   ;Was a key pressed?
         BPL GETKEY     ;No, so repeat
         LDA KEYBOARD   ;Get the key
         STA SVKEY
         LDX BUFFPOS
         LDA INBUFF,X
         BNE :2
         LDA #$A0
:2       JSR COUT
         LDA #$88
         JSR COUT
         BIT STROBE     ;Yes, so clear strobe
         RTS            ;Return to caller
FLASH    LDA CUR_CHAR   ;Display cursor or character?
         BEQ DOCURSOR   ;Go display cursor
         LDX BUFFPOS    ;Get position in buffer
         LDA INBUFF,X   ;Get character there
         BNE :1         ;If it's not a zero, print char
         LDA #$A0       ;If a zero, print a space
:1       JSR COUT
         LDA #$88
         JSR COUT
         LDA #$50       ;Modify counter
         STZ TIMER      ;Clear the timer
         STA TIMER+1
         STZ CUR_CHAR   ;Next time print cursor
         JMP GETKEY
DOCURSOR LDA MODE       ;Which cursor?
         BEQ :2         ;If it's zero, do insert cursor
         LDX BUFFPOS    ;Get position in buffer
         LDA INBUFF,X   ;Get character in position
         BNE *+2        ;If not on end, go
:1       LDA #$A0       ;Cursor is inverse space
         AND #$7F       ;Make char inverse
         BRA *+2
:2       LDA #"_"       ;Cursor is underline
         JSR COUT       ;Print the cursor
         LDA #$88       ;Print backspace
         JSR COUT
         LDA #$40       ;Modify counter
         STZ TIMER      ;Clear timer
         STA TIMER+1
         DEC CUR_CHAR   ;Next time print letter
         JMP GETKEY
PRINT    PLA            ;Get low byte of address
         STA TEMP       ;Save it
         PLA            ;Get high byte
         STA TEMP+1     ;Save the address
:1       INC TEMP
         BNE :2
         INC TEMP+1
:2       LDA (TEMP)     ;Get char from string
         BEQ :3         ;If zero, go end
         JSR COUT       ;Print the character
         BRA :1         ;Do next char
:3       LDA TEMP+1     ;Get HOB of address
         PHA            ;Save it on stack
         LDA TEMP       ;Get LOB of address
         PHA            ;Save it on stack
         RTS            ;Return past text
MOUSEOUT PHA            ;Save character to be printed
         LDA #$1B       ;Turn on MouseText
         JSR COUT
         LDA #$0F
         JSR COUT
         PLA            ;Restore character
         JSR COUT       ;Print the character
         LDA #$0E       ;Turn off MouseText
         JSR COUT
         LDA #$18
         JMP COUT
PRINTDEC PHY            ;Save entry Y-reg
         JSR LINPRT     ;Print number in decimal
         PLY            ;Restore Y-reg
         RTS
BOTTOM   STZ CH         ;Move to edge of screen
         PHA            ;Save entry Acc
         LDA #23
         JSR TABV       ;Move to bottom of screen
         PLA            ;Restore Accumulator
         RTS
BUFF_MEM LDY #$FF       ;Clear index
:1       INY
         LDA INBUFF,Y   ;Get character from buffer
         STA (POSPTR),Y ;Put it in memory
         BNE :1         ;If not the end, continue
         RTS
PRINTLC  JSR BOTTOM     ;Move to bottom row
         JSR PRINT      ;Print the next line
         ASC "Line ",00
         LDX LINENUM    ;Get line number
         LDA LINENUM+1
         JSR PRINTDEC   ;Print it in decimal
         JSR PRINT      ;Print the next line
         ASC "  Column ",00
         LDX BUFFPOS    ;Get the column number
         INX
         LDA #$00
         JSR PRINTDEC   ;Print it as a decimal and return
         LDA #$A0
         JSR COUT       ;Print a space
         LDA SCRLINE    ;Get the line we were on
         JSR TABV       ;and go there
         LDA BUFFPOS    ;Get buffer position
         STA CH         ;Move to there
         RTS
STORE    BIT CHANGED    ;Was the line changed
         BEQ :1         ;No, so don't save it
         LDA LINELEN    ;Get length of old line
         CMP LENGTH     ;Compare it to new length
         BCS MV_BACK    ;Go move back
         BCC MV_FRWD    ;Go move forward
         JSR BUFF_MEM   ;Move from buffer to memory
:1       LDA LENGTH     ;Find next line
         CLC
         ADC POSPTR
         STA POSPTR
         BCC :2
         INC POSPTR+1
:2       RTS
MV_BACK  JSR BUFF_MEM   ;Move from buffer to memory
         CLC
         LDA LINELEN    ;Find start of old next line
         ADC POSPTR
         STA TEMP
         LDA #$00
         ADC POSPTR+1
         STA TEMP+1
         LDA LENGTH     ;Find start of new next line
         CLC
         ADC POSPTR
         STA POSPTR
         BCC :1
         INC POSPTR+1
:1       STA TEMP       ;Copy POSPTR to move pointer
         LDA POSPTR+1
         STA TEMP+1
         LDY #$00       ;Clear index
:2       LDA (TEMP),Y   ;Get from old location
         STA (TEMP2),Y  ;Put in new location
         CMP #$FF       ;Is it the end of the listing?
         BNE :2A
         TYA            ;Find new end address
         CLC
         ADC TEMP2
         STA ENDPTR
         LDA #$00
         ADC TEMP2+1
         STA ENDPTR+1
         RTS
:2A      INY
         BNE :2         ;Go do bext byte
         INC TEMP+1     ;Move to next page
         INC TEMP2+1
         BRA :2
MV_FRWD  CLC
         LDA LENGTH     ;Get length of new line
         ADC POSPTR     ;Find destination address
         STA TEMP
         LDA #$00
         ADC POSPTR+1
         STA TEMP+1
         SEC
         LDA LENGTH     ;Get length of new line
         SBC LINELEN    ;Find difference in length
         CLC
         ADC ENDPTR     ;Find new end
         STA TEMP2
         PHA            ;Save low byte
         LDA #$00
         ADC ENDPTR+1
         STA TEMP2+1
         PHA            ;Save high byte
:1       LDA (ENDPTR)   ;Get char from end
         STA (TEMP2)    ;Put it in the new end
         LDA TEMP2      ;Check if we are done
         CMP TEMP
         BNE :1A
         LDA TEMP2+1
         CMP TEMP+1
         BEQ :2
:1A      DEC ENDPTR     ;Move one byte back
         LDA ENDPTR     ;Get low-byte of address
         CMP #$FF       ;Do we need to change pages?
         BNE :1B
         DEC ENDPTR+1   ;Yes, so do it
:1B      DEC TEMP2      ;Move TEMP2 back too
         LDA TEMP2
         CMP #$FF
         BNE :1 
         DEC TEMP2+1
         BRA :1         ;Go do it again
:2       PLA            ;Get new ENDPTR
         PLX
         STX ENDPTR     ;Save it
         STA ENDPTR+1
         JSR BUFF_MEM
         LDA LENGTH     ;Get new length
         CLC
         ADC POSPTR     ;Find next line
         STA POSPTR
         BCC :3
         INC POSPTR+1
:3       RTS
MV_DOWN  INC LINENUM    ;Increment the line number
         BNE :1
         INC LINENUM+1
:1       LDA SCRLINE    ;Get screen line number
         CMP #21        ;Is it the bottom row?
         BEQ :2
         INC SCRLINE    ;Move one line down
         BRA :3
:2       LDY #$FF       ;Clear index
:2A      INY
         LDA (TOPSCR),Y
         BNE :2A
         INY
         TYA
         CLC            ;Prepare for addition
         ADC TOPSCR     ;Move top of screen one line down
         STA TOPSCR
         BCC :2B
         INC TOPSCR+1
:2B      LDA #$8A
         JMP COUT
:3       JMP CROUT      ;Print a carriage return
FIX_LINE LDX LENGTH     ;Remove all trailing zeros
         BEQ :2
:1       DEX
         LDA INBUFF,X
         CMP #$A0
         BNE :1A
         STZ INBUFF,X
         BRA :1
:1A      INX
:2       INX            ;Include $00 in length
         STX LENGTH
         RTS            ;Return to program
INSRTLIN LDX BUFFPOS    ;Get character where RETURN
         LDA INBUFF,X   ;was pressed
         BNE :4         ;If not on the end, return
         LDA (POSPTR)   ;Is it the end of listing?
         CMP #$FF
         BEQ :4         ;Yes, so return
         LDX ENDPTR
         LDA ENDPTR+1
         STX TEMP
         STA TEMP+1
         LDY #$00       ;Move everything over one line
:1       LDA (TEMP),Y
         INY
         STA (TEMP),Y
         DEY
         LDA TEMP       ;Are we done?
         CMP POSPTR
         BNE :1A
         LDA TEMP+1
         CMP POSPTR+1
         BEQ :2
:1A      LDA TEMP
         BNE :1B
         DEC TEMP+1
:1B      DEC TEMP
         BRA :1
:2       INC ENDPTR
         BNE :2A
         INC ENDPTR+1
:2A      LDA #$00
         STA (POSPTR),Y   ;Insert new line
         LDX SCRLINE
         CPX #21
         BEQ :4
         LDY POSPTR
         LDA POSPTR+1
         STY TEMP
         STA TEMP+1
         INX
         TXA
         JSR TABV
:3       JSR PRT_LINE
         BCS :4
         CPX #21
         BEQ :4
         JSR CROUT
         INX
         JSR NXT_LINE   ;Find address on next line
         BRA :3         ;Go do next line
:4       STZ BUFFPOS
         RTS
PRT_LINE STZ CH         ;Move to start of line
         LDY #$00       ;Clear index
:1       LDA (TEMP),Y   ;Get character from line
         INY
         CMP #$00       ;Is it end of line?
         BEQ :2
         CMP #$FF       ;Is it end of file?
         BEQ :3
         JSR COUT       ;Print char
         BRA :1
:2       PHY
         JSR CLREOL     ;Clear the rest of the line
         PLY
         CLC
         RTS
:3       PHY
         JSR CLREOP
         PLY
         SEC
         RTS
NXT_LINE TYA            ;Move length to Acc
         CLC            ;Prepare for addition
         ADC TEMP       ;Add it to print pointer
         STA TEMP
         BCC :1
         INC TEMP+1
:1       RTS            ;Return
