; ********************************************************************************
; MTRX2700 Lab 2
; Task 1 Part 1: "Serial Output'
; GROUP:
; MEMBERS:
; DESCRIPTION: 
; MODIFIED:
; ********************************************************************************

; export symbols
            XDEF                Entry, _Startup ; export 'Entry' symbol
            ABSENTRY            Entry           ; for absolute assembly: mark this as application entry point

; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
                ORG             $FFFE
                DC.W            Entry           ; Reset Vector
                
; ISR config: Timer 4
                ORG             $FFE6
                DC.W            OCISR
                
ROMStart        EQU             $4000           
PERIOD          EQU             32000

; variable/data section
                ORG             RAMStart

str1            FCB             "Bullshit string 1"
str2            FCB             "second bullshit string"
tmp             FCB             $00
TOSEND          FCB             $00

; code section
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts
                
                ; configure the timer system
CONFIG          SEI                             ; disable all interrupts
                MOVB            #$01,TCTL1      ; set up output to toggle
                MOVB            #$10,TIOS       ; select channel 4 for output compare
                MOVB            #$80,TSCR1      ; enable timers
                MOVB            #$04,TSCR2      ; prescaler div 16
                BSET            TIE,#$10        ; enable timer interrupt 4
                CLI
                
                ; enable the LEDs
                BSR             LED_ENABLE
                
                ; loop forever (wait for interrupts)
LOOP:           *

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
