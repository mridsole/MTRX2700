; ********************************************************************************
; MTRX1702 LAB 1 
; Task 2 Part 2: "The 7 Segment Display"
; GROUP 6
; DESCRIPTION: this program writes 'FISH' to the 7 segment display
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

; display codes for the characters 'F I S H'
SEG_DISP_F      EQU             $71
SEG_DISP_I      EQU             $06
SEG_DISP_S      EQU             $6D
SEG_DISP_H      EQU             $65

                ORG             RAMStart
                ; data goes here - no data for now
                
                ; start writing code at the start of ROM
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts

                LDAA            #$FF            ; load 11111111 into reg A
                STAA            DDRP            ; configure port P as output
                STAA            DDRB            ; configure port B as output

fish_loop:      JSR             write_fish      ; jump to the write_fish subroutine
                BRA             fish_loop       ; keep running said subroutine

; ********************************************************************************
; SUBROUTINE: write_fish
; ARGS: None
; writes FISH to the four 7 seg displays
; ********************************************************************************
write_fish:
                LDAA            #SEG_1_ON       ; ...
                STAA            PTP             ; ... select the first display for writing
                LDAA            #SEG_DISP_F     ; ...
                STAA            PORTB           ; ... write 'F' to the first 7 seg

                ; wait for a little bit before writing to the next display:
                JSR             delay_small    

                LDAA            #SEG_2_ON       ; ...
                STAA            PTP             ; ... select the second display for writing
                LDAA            #SEG_DISP_I     ; ...
                STAA            PORTB           ; ... write 'I' to the second 7 seg

                ; wait a little bit
                JSR             delay_small
                
                LDAA            #SEG_3_ON       ; ...
                STAA            PTP             ; ... select the third display for writing
                LDAA            #SEG_DISP_S     ; ...
                STAA            PORTB           ; ... write 'S' to the third 7 seg

                ; wait a little bit
                JSR             delay_small
                
                LDAA            #SEG_4_ON       ; ...
                STAA            PTP             ; ... select the fourth display for writing
                LDAA            #SEG_DISP_H     ; ...
                STAA            PORTB           ; ... write 'H' to the fourth seg

                ; wait a little bit
                JSR             delay_small

                RTS                             ; return
                
                

; ********************************************************************************
; SUBROUTINE: delay_small
; ARGS: None
; waits for some small amount of time - (probably around 0.5 ms)
; used for leaving one 7 seg display on for a bit before cycling to the next
; ********************************************************************************
delay_small:
                PSHX                            ; push X to stack, in case it's in use
                LDX             #500            ; load 500 into X, to count down
                
delay_small_L:
                DEX                             ; decrement X each loop iteration
                BNE             delay_small_L   ; if X isn't zero, keep looping
                
                PULX                            ; pop X off the stack
                RTS                             ; return from the subroutine
