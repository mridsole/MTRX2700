; ********************************************************************************
; MTRX2700 Lab 2
; Task 2 Part 1: "Timer System"
; GROUP: 7
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

; ISR config - timer 4:
                ORG             $FFE6
                DC.W            isr_timer
                
ROMStart        EQU             $4000           
TDRE_bitmask    EQU             $80

; variable/data section
                ORG             RAMStart


; our data strings - terminated by a null character:
str1            FCB             "first thingy",$00
str2            FCB             "second thingy",$00

; code section
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                
; configure the registers:
                SEI                             ; disable all interrupts
                MOVB            #$00,TCTL1      ; set up output to toggle
                MOVB            #$10,TIOS       ; select channel 4 for output compare
                MOVB            #$80,TSCR1      ; enable timers
                MOVB            #$00,TSCR2      ; prescaler div 16
                BSET            TIE,#$10        ; enable timer interrupt 4
                MOVB            #$FF,DDRT
                MOVB            #$01,PTT
                CLI
                
 ; configure LED ports:
                MOVB            #$FF,DDRB
                MOVB            #$FF,DDRJ
                MOVB            #$00,PTJ
                MOVB            #$00,PORTB

; loop forever
loop            BRA             loop

; ******************************************************************************** 
; ISR: isr_timer
; ********************************************************************************
isr_timer:
                LDD             TCNT            ; get current count
                ADDD            #200            ; add a number to it
                STD             TC4             ; reload TOC2
                MOVB            #$10,TFLG1      ; reset the main timer interrupt flag
                LDX             #30
lp:             DEX             
                BNE             lp
                RTI
