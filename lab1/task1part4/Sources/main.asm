; ********************************************************************************
; MTRX2700 LAB 1 
; Task 1 Part 4: "Writing Your Own Code"
; GROUP 6
; DESCRIPTION: flashes an LED at 0.5 Hz (1 second on, 1 second off)
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

LEDON           EQU             $01             ; value to write to port B

                ORG             RAMStart
                ; data goes here
                ; no data this time
                
                ; start writing code at the start of ROM
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts

                LDAA            #$FF            ; load 11111111 into A
                STAA            DDRB            ; configure port B as an output (data bus port)
                STAA            DDRJ            ; configure port J as an output (LED enable port)
                LDAA            #$00            ; need to write $00 to port J ...
                STAA            PTJ             ; ... to enable LEDs

main_loop:      LDAA            #LEDON          ; load accumulator with value for port B
                STAA            PORTB           ; write 00000001 to port B - turns 1 LED on
                BSR             delay_1_sec     ; delay for one second
                CLR             PORTB           ; write 00000000 to port B - turns all LEDs off
                BSR             delay_1_sec     ; delay for one second
                BRA             main_loop       ; keep looping
                

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
