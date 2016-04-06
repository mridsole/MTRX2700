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

str1            FCB             "first string"
str2            FCB             "second thingy"

; code section
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts
                
                ; configure the serial communications interface
config_sci      SEI                             ; disable all interrupts
                
                ; TODO: find appropriate baud rate value
                MOVB            #$01,SCIOBDL    ; set the baud rate low byte
                MOVB            #$01,SCIOBH     ; set the baud rate higher bits
                
                ; now set word length and wake up


                MOVB            #$01,TCTL1      ; set up output to toggle
                MOVB            #$10,TIOS       ; select channel 4 for output compare
                MOVB            #$80,TSCR1      ; enable timers
                MOVB            #$04,TSCR2      ; prescaler div 16
                BSET            TIE,#$10        ; enable timer interrupt 4
                CLI                             ; enable interrupts
                
                ; enable the LEDs
                BSR             LED_ENABLE
                
                ; loop forever (wait for interrupts)
LOOP:           *

OCISR:

LED_ENABLE
                MOVB            #$FF,DDRB
                MOVB            #$FF,DDRJ
                BCLR            PTJ,$02
                CLR             PORTB
                RTS

; ********************************************************************************
; SUBROUTINE: delay_1_sec
; ARGS: None
; waits exactly one second, using an outer and inner (nested) loop 
; with predefined constants - see logbook for derivation
; (also uses a secondary smaller loop for fine tuning)
; ********************************************************************************
delay_1_sec:
                PSHX                            ; push X to the stack, in case the  caller is using
                PSHY                            ; same thing for Y
                LDX             #1000           ; load decrement counter (constant C1) in x
delay_1_sec_L:  
                LDY             #5998           ; load decrement counter (constant C2) in y
delay_1_sec_L2: 
                DEY                             ; decrement Y every inner loop cycle
                BNE             delay_1_sec_L2  ; if Y isn't 0, branch to the inner loop
                DEX                             ; decrement X every outer loop cycle
                BNE             delay_1_sec_L   ; if X isn't 0, branch to the outer loop
            
; this gets pretty close, but not quite: so run another small loop to make up for it
                LDX             #996            ; constant C3
delay_1_sec_L3: 
                DEX                             ; decrement X
                BNE             delay_1_sec_L3  ; if X isn't zero, branch to loop
                             
; before returning, pop original x and y for the caller to use off the stack
                PULY                            ; pop Y first (correct reverse order)
                PULX                            ; then pop X
                RTS                             ; return
