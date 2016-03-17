; ********************************************************************************
; MTRX1702 LAB 1 
; Task 2 Part 1: "Switches and LEDs"
; GROUP 6
; DESCRIPTION: this program continuously outputs the state of the DIP switches
;               to the row of LEDs
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

                ORG             RAMStart
                ; data goes here - no data for now
                
                ; start writing code at the start of ROM
                ORG             ROMStart        

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts

                LDAA            #$00            ; load $00 into register A
                STAA            DDRH            ; configure port H (the DIP switches) as an input

                LDAA            #$FF            ; load $FF into register A
                STAA            DDRB            ; configure port B (the data bus - controls LEDs) as output
                STAA            DDRJ            ; configure port J as output
                
                LDAA            #$00
                STAA            PTJ             ; enable the LEDs by writing $00 to port J
                
read_write_LEDs:
                LDAA            PTH             ; read the DIP switches into register A
                STAA            PORTB
                BRA             read_write_LEDs
