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

; variable/data section
                ORG             RAMStart

; code section
                ORG             ROMStart

Entry:
_Startup:
                LDS             #RAMEnd+1       ; initialize the stack pointer
                CLI                             ; enable interrupts
mainLoop:

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
                ORG             $FFFE
                DC.W            Entry           ; Reset Vector
