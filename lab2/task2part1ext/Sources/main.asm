; ********************************************************************************
; MTRX2700 Lab 2
; Task 2 Part 1: "Timer System" Extension
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

; SCI1 RIE
                ORG             $FFD4
                DC.W            isr_sci_receive

ROMStart        EQU             $4000

; the PWM period, in cyles * 32 (after prescaling)
PERIOD          EQU             53250
                
; variable/data section
                ORG             RAMStart

; 0 = output signal is currently LOW
; 1 = output signal is currently HIGH
CYCLE_STATE     FCB             $01

; store the prescaled cycles we have to jump
; start with a square wave (so high time = low time)
CYCLES_HIGH     FDB             26625
CYCLES_LOW      FDB             26625

; code section
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer

                SEI                             ; disable all interrupts

; configure the serial communications interface:
                MOVB            #$00,SCI1BDH    ; baud rate higher bytes
                MOVB            #$9C,SCI1BDL    ; baud rate lower bytes (156)
                MOVB            #$00,SCI1CR1    ; M = 0, WAKE = 0
                MOVB            #$24,SCI1CR2    ; use receive interrupts
                
; configure the timer system registers:
                MOVB            #$00,TCTL1      ; set up output to toggle
                MOVB            #$10,TIOS       ; select channel 4 for output compare
                MOVB            #$80,TSCR1      ; enable timers
                MOVB            #$00,TSCR2      ; prescaler div 16
                BSET            TIE,#$10        ; enable timer interrupt 4
                
                ; NOT SURE IF THIS IS NECESSARY - check on the actual board
                MOVB            #$FF,DDRT       ; configure port T as output

                CLI                             ; re-enable all interrupts
                
 ; configure DIP switches ports:
                MOVB            #$00,DDRH       ; configure DIP switches as inputs

; loop forever - keep polling the DIP switches for the duty cycle
mainLoop:
                LDAB            PTH
                BSR             compute_duty_cycle
                BRA             mainLoop

; ******************************************************************************** 
; SUBROUTINE: compute_duty_cycle
; ARGS: B: the duty cycle, from 0-255
; computes the number of cycles to wait during the HIGH and the LOW parts of 
; the period (stores it in memory at CYCLES_HIGH and CYCLES_LOW)
; ********************************************************************************
compute_duty_cycle:
                PSHA                            ; push A to stack in case it's in use
                LDAA            #0              ; load 0 into A
                LDY             #PERIOD         ; load the period into Y
                EMUL                            ; extended multiply D and Y
                LDX             #255            ; load 255 into X
                EDIV                            ; extended divide Y:D by X
                STY             CYCLES_HIGH     ; store the HIGH result
                LDD             #PERIOD         ; load the period into D
                SUBD            CYCLES_HIGH     ; subtract the HIGH result to obtain LOW
                STD             CYCLES_LOW      ; store the LOW result
                PULA                            ; pull A back from the stack
                RTS                             ; return
                
; ******************************************************************************** 
; ISR: isr_sci_receive
; ********************************************************************************
isr_sci_receive:
                LDAA            SCI1SR1
                LDAA            SCI1DRL
                RTI

; ******************************************************************************** 
; ISR: isr_timer
; ********************************************************************************
isr_timer:
                LDD             TCNT            ; load current timer count into D
                LDAA            CYCLE_STATE     ; load the state of the cycle into A
                CMPA            #$00            ; compare it with zero
                BEQ             isr_timer_high  ; if 0, write high

                ADDD            CYCLES_LOW
                STD             TC4
                MOVB            #$10,TFLG1
                MOVB            #$00,PTT
                MOVB            #$00,CYCLE_STATE
                BRA             isr_timer_end

isr_timer_high:
                ADDD            CYCLES_HIGH     
                STD             TC4
                MOVB            #$10,TFLG1
                MOVB            #$10,PTT
                MOVB            #$01,CYCLE_STATE
                BRA             isr_timer_end
                
isr_timer_end:
                RTI
