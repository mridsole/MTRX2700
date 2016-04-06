; ********************************************************************************
; MTRX2700 Lab 2
; Task 1 Part 1: "Serial Output'
; GROUP:
; MEMBERS:
; DESCRIPTION: 
; ********************************************************************************

; export symbols
            XDEF                Entry, _Startup ; export 'Entry' symbol
            ABSENTRY            Entry           ; for absolute assembly: mark this as application entry point

; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 
                
ROMStart        EQU             $4000           
PERIOD          EQU             32000

; variable/data section
                ORG             RAMStart

str1            FCB             "Bullshit string 1"
str2            FCB             "second bullshit string"
tmp             FCB             $00

; code section
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts
                
CONFIG          SEI
                MOVB            #$01,TCTL1
                MOVB            #$10,TIOS
                MOVB            #$80,TSCR1
                MOVB            #$04,TSCR2
                BSET            TIE,#$10
                CLI

OCISR:
                LDD             TCNT            ; get current count
                ADDD            #PERIOD         ; add the period
                STD             TC4             ; reload TOC2
                LDAA            TOSEND          ; initial value = $00
                INCA                            ; increment a
                STAA            TOSEND          ; save into memory
                STAA            PORTB           ; send A to LEDs
                MOVB            #$10,TFLG1      ; ...
                RTI

LED_ENABLE
                MOVB            #$FF,DDRB
                MOVB            #$FF,DDRJ
                BCLR            PTJ,$02
                CLR             PORTB
                RTS
                
mainLoop:

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
                ORG             $FFFE
                DC.W            Entry           ; Reset Vector
                
; ISR config: Timer 4
                ORG             $FFE6
                DC.W            OCISR
