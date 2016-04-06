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
                
; configure the serial communications interface:
config_sci      SEI                             ; disable all interrupts
                
                ; see logbook for the calculations - baud rate is 9600, so here
                ; we put 156 (0x9C) into the baud rate registers
                MOVB            #$00,SCI1BDH    ; set the baud rate low byte
                MOVB            #$9C,SCI1BDL    ; set the baud rate higher bits
                
                ; now set word length and wake up, and parity configuration
                ; M = 0 (8 bit data), WAKE = 0, and no parity:
                MOVB            #$00,SCI1CR1

                ; complete SCI config by writing to the SCI control register 2
                ; only use the transmission functionality (no interrupts)

                MOVB            #$08,SCI1CR2
                CLI                             ; enable interrupts
                
; write to the SCI in a loop
LOOP_WRITE_SCI: 
                LDX             #str1           ; load address of start of str1 into A
                JSR             write_str_sci   ; write the first string
                JSR             delay_1_sec     ; delay for about a second

                ; write new line characters
                JSR             write_newline_sci               

                LDX             #str2           ; load address of start of str2 into A
                JSR             write_str_sci   ; write the second string
                JSR             delay_1_sec     ; delay for about a second
                
                ; write new line characters
                JSR             write_newline_sci               

                BRA             LOOP_WRITE_SCI  ; keep looping

; ******************************************************************************** 
; SUBROUTINE: write_newline_sci
; ARGS: None
; writes \r\n (carriage return then a new line character) to the terminal
; ********************************************************************************
write_newline_sci:
                PSHB                            ; put B on the stack in case it's in use
                LDAB            #$0D            ; load B with ASCII for \r (carriage ret.)
                JSR             write_byte_sci  ; write it to SCI
                LDAB            #$0A            ; load B with ASCII for \n (new line)
                JSR             write_byte_sci  ; write it to SCI
                PULB                            ; pull B back from stack
                RTS                             ; return

; ******************************************************************************** 
; SUBROUTINE: write_str_sci
; ARGS: X: the address of the start of the string to write
; writes a null-terminated (ending in #$00) string to the serial communications
; interface
; ********************************************************************************
write_str_sci:
                PSHB                            ; put B on the stack in case it's in use
                LDAB            X               ; load B with value at address in X
write_str_sci_L:
                JSR             write_byte_sci  ; write the character to the SCI
                INX                             ; increment X along the string
                LDAB            X               ; load B with the value at address in X
                CMPB            #$00            ; compare the current char with #$00
                BNE             write_str_sci_L ; if the char is the null char, exit the loop

                PULB                            ; pull B back from the stack
                RTS                             ; return

; ********************************************************************************
; SUBROUTINE: write_byte_sci
; ARGS: B: the ASCII character to write 
; writes one byte to the serial communications interface
; keeps polling until the TDRE byte is 1, then writes it
; ********************************************************************************
write_byte_sci:
                PSHA                            ; put A on the stack in case it's in use
write_byte_sci_L:
                LDAA            SCI1SR1         ; poll the SCI status register
                ANDA            #TDRE_bitmask   ; isolate the TDRE bit
                ; if TDRE is 0, keep polling:
                BEQ             write_byte_sci_L 
                STAB            SCI1DRL         ; TDRE is 1, so write the data
                
                PULA                            ; pull A back from the stack
                RTS                             ; return
                
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
