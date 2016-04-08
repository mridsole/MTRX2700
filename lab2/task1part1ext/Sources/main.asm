; ********************************************************************************
; MTRX2700 Lab 2
; Task 1 Part 1: "Serial Output" Extension
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
RDRF_bitmask    EQU             $20             ; Receive Data Register Full bitmask

; variable/data section
                ORG             RAMStart

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
                ; only use the polling receive functionality (no interrupts)

                MOVB            #$04,SCI1CR2
                CLI                             ; enable interrupts

LED_CONFIG:                                     ; configure the relevant LED ports
                LDAA            #$FF
                STAA            DDRB            ; configure port B (data bus) as an output
                STAA            DDRJ            ; configure port J as an output
                LDAA            #$00
                STAA            PTJ             ; enable all of the LEDs

                LDX             #0
                
                ; write to the SCI in a loop
LOOP_READ_SCI: 
                LDAA            SCI1SR1         ; poll the SCI status register
                ANDA            #RDRF_bitmask   ; isolate the RDRF bit
                BEQ             LOOP_READ_SCI   ; if RDRF is 0, keep polling
                INX                             ; ... debugging
                LDAA            SCI1DRL         ; read some data in from the SCI
                STAA            PORTB           ; write the data to the LEDs
                BRA             LOOP_READ_SCI  ; keep looping

