; ********************************************************************************
; MTRX2700 LAB 1 
; Task 2 Part 2: "The 7 Segment Display" Extension 1
; GROUP 6
; DESCRIPTION: this program monitors the DIP switches and writes the data in hex
;               to the seven segment display
; ******************************************************************************** 

                ; export symbols
                XDEF            Entry, _Startup ; export 'Entry' symbol
                ABSENTRY        Entry           ; for absolute assembly: mark this as application entry point

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
                ORG             $FFFE
                DC.W            Entry           ; Reset Vector

                ; Include derivative-specific definitions 
                INCLUDE         'derivative.inc' 

ROMStart        EQU             $4000           ; start address of read only memory

; hex codes for choosing which 7 seg display to write to
SEG_1_ON        EQU             $0E
SEG_2_ON        EQU             $0D
SEG_3_ON        EQU             $0B
SEG_4_ON        EQU             $07

; display codes for the 7 segment display
SEG_0           EQU             $3F
SEG_1           EQU             $06
SEG_2           EQU             $5b
SEG_3           EQU             $4F
SEG_4           EQU             $66
SEG_5           EQU             $6D
SEG_6           EQU             $7D
SEG_7           EQU             $07
SEG_8           EQU             $7F
SEG_9           EQU             $6F
SEG_A           EQU             $77
SEG_B           EQU             $7C
SEG_C           EQU             $39
SEG_D           EQU             $5E
SEG_E           EQU             $79
SEG_F           EQU             $71

                ; our data:
                ORG             RAMStart
DIP_DATA        FCB             $00             ; temp storage for the dip switch data
B_TMP           FCB             $00             ; temp store for B

; the lookup table starts here
SEG_LOOKUP      FCB             SEG_0
                FCB             SEG_1
                FCB             SEG_2
                FCB             SEG_3
                FCB             SEG_4
                FCB             SEG_5
                FCB             SEG_6
                FCB             SEG_7
                FCB             SEG_8
                FCB             SEG_9
                FCB             SEG_A
                FCB             SEG_B
                FCB             SEG_C
                FCB             SEG_D
                FCB             SEG_E
                FCB             SEG_F

                ; start writing the program at the start of ROM
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts

part2_main:
                ; set the dip switch port (H) to be an input
                LDAA            #$00            
                STAA            DDRH            ; set port H to be input

                ; set the 7seg data port (B) and the selection port (P) to be output
                LDAA            #$FF            
                STAA            DDRB            ; set port B to be output
                STAA            DDRP            ; set port P to be output

main_loop:      BSR             read_write_dip  ; branch to the read_write_dip subroutine
                BRA             main_loop       ; keep looping

; ********************************************************************************
; SUBROUTINE: read_write_dip
; ARGS: none
; the main loop of the program - reads the data and writes it to the 7 seg display
; ******************************************************************************** 
read_write_dip:
                LDAB            PTH             ; read the 8 bit num from the dip switches

                ; (this was used for testing in the simulator (without the board)):
                ; LDAB            #$5B            ; STUB THIS FOR NOW

                STAB            DIP_DATA        ; store B in memory (necessary for AND)
                
                ; bit mask to get the least significant four bits:
                LDAB            #$0F            ; load the mask into B
                ANDB            DIP_DATA        ; perform bitwise AND
                
                ; now look up the 7 seg code, which will be stored in A
                JSR             seg_lookup
                TAB                             ; transfer A (the 4 bit value) to B

                ; store the code for turning on the last 7 seg in A:
                LDAA            #SEG_4_ON       
                JSR             write_7seg      ; write the data to the 7 seg display
                JSR             delay_small     ; delay a little bit before writing the next display

                ; the least significant 4 bits are done - now do the first 4:

                LDAB            DIP_DATA        ; load the stored dip switch data
                
                ; shift to the right four times:
                ASRB
                ASRB
                ASRB
                ASRB

                ; look up the 7 seg code
                JSR             seg_lookup
                TAB                             ; transfer A (the 4 bit value) to B
                
                LDAA            #SEG_3_ON       ; store code for turning on the second last 7 seg display in A:
                JSR             write_7seg      ; write data to the 7 seg display:
                JSR             delay_small     ; delay a little bit before writing the next display

                RTS                             ; return
                
                
; ********************************************************************************
; SUBROUTINE: write_7seg
; ARGS: register A: which - register B: data
; writes the data to the seven seg given by 'which'
; ********************************************************************************
write_7seg:
                STAA            PTP             ; select the 7 seg(s) to write to
                STAB            PORTB           ; write the data to the 7 seg
                RTS                             ; return


; ********************************************************************************
; SUBROUTINE: delay_small
; ARGS: none
; a small delay, probably about 500 microseconds (or maybe less)
; ********************************************************************************
delay_small:
                PSHX                            ; push X to stack in case it's in use
                LDX             #200            ; load 1000 into X
delay_small_L:
                DEX                             ; decrement X
                BNE             delay_small_L   ; loop if X isn't 0
                
                PULX                            ; take X back from stack

                RTS                             ; return


; ********************************************************************************
; SUBROUTINE: seg_lookup
; ARGS: register B: the hex value to look up
; RETURNS: register A: the hex 7 seg code for that value
; ********************************************************************************
seg_lookup:
                PSHX                            ; push X to stack in case it's in use
                LDX             #SEG_LOOKUP     ; load the SEG_LOOKUP address into X
                ABX                             ; add B to X
                LDAA            0,X             ; store the 7 seg code in A

                PULX                            ; pull the origin X back

                RTS                             ; return
