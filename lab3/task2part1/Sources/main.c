/* ********************************************************************************
	MTRX2700 Lab 3
	TASK 2 PART 1: "Serial IO (again)"
	GROUP: ??
	MEMBERS: ???
	DESCRIPTION: does a thing
	MODIFIED: yer
******************************************************************************** */

#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */

#define SEND_STACK_SIZE (unsigned char)32

// stack used for buffering data to transmit via SCI  
char send_stack[SEND_STACK_SIZE];

// position of stack (max SEND_STACK_SIZE - 1)
unsigned char send_stack_pos = 0;

// configure the serial communications interface
void config_SCI(void) {

	// configure baud rate (see the previous lab)
	SCI1BDH = 0x00;
	SCI1BDL = 0x9C;

	// control registers - M = 0, WAKE = 0, no parity, use transmit and receive interrupts
	SCI1CR1 = 0x00;
	SCI1CR2 = 0xAC;

	return;
}

void main_loop(void) {
	
	// this one's entirely interrupt driven
}

void main(void) {
	
	// disable interrupts while configuring the SCI
	DisableInterrupts;
	config_SCI();
	EnableInterrupts;

	// main loop
	for(;;) {
		main_loop();
	} 
}

// interrupt for receiving a character from the terminal
interrupt 21 void SCI1_ISR(void) {

	// if received a character, add to the stack (if there's space for it)
	if (SCI1SR1 & 0x20) {
		char data_received = SCI1DRL;
		if (send_stack_pos < SEND_STACK_SIZE) {
			send_stack[send_stack_pos] = data_received;
			send_stack_pos++;
		}
	} 
	
	// if a character is ready to send, send one off the stack
	if (SCI1SR1 & 0x40) {
		if (send_stack_pos > 0) {
			send_stack_pos--;
			SCI1DRL = send_stack[send_stack_pos];
		}
	}

	return;
}
