; ********************************************************************************
; MTRX2700 Lab 2
; Task 1 Part 1: "Serial Output" Extension
; GROUP: 7
; MEMBERS: Xinzan Guo, David Rapisarda, Thomas T. Cooper, Hughson Xu
; DESCRIPTION: Continuously polls the serial port and sends character data to the
;               LEDs as soon as it is received.
; MODIFIED: 10:00 13/04/2016
;               (added more detailed header information)
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
                MOVB            #$FF,DDRB       ; configure port B (data bus) as output
                MOVB            #$FF,DDRJ       ; configure port J (LED selection) as output
                MOVB            #$00,PTJ        ; select all LEDs
                
                ; write to the SCI in a loop
LOOP_READ_SCI: 
                LDAA            SCI1SR1         ; poll the SCI status register
                ANDA            #RDRF_bitmask   ; isolate the RDRF bit
                BEQ             LOOP_READ_SCI   ; if RDRF is 0, keep polling
                MOVB            SCI1DRL,PORTB   ; write the data to the LEDs
                BRA             LOOP_READ_SCI   ; keep looping
