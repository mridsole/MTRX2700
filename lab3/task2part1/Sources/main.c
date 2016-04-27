/* ********************************************************************************
	MTRX2700 Lab 3
	TASK 2 PART 1: "Serial IO (again)"
	GROUP: 5
	MEMBERS: John Sumskas, Justin Ko, Jasmine Chen, Jacqui Dielwart, David Rapisarda
	DESCRIPTION: whenever a character is sent to the SCI, "0xXY data received" is
		sent back. Maintains a stack buffer in order to respond to quickly incoming 
		data
	MODIFIED: 26/04/2016
******************************************************************************** */

#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */

#define SEND_STACK_SIZE (unsigned char)32

// stack used for buffering data to transmit via SCI  
char send_stack[SEND_STACK_SIZE];

// -1 => the stack is empty
// maximum value is SEND_STACK_SIZE - 1
char send_stack_pos = -1;

// the ascii codes for the data received
unsigned char data_digits_ascii[2];

// what sending state are we in?
enum { 
	SEND_0, 
	SEND_x,
	SEND_DIGIT_0, 
	SEND_DIGIT_1,
	SEND_TAIL_MSG 
} send_state = SEND_0;

// the message to send after the data
char tail_msg[] = " data received\r\n\0";

// where we're at in the tail message
unsigned int tail_msg_pos = 0;

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

// get the 2 ASCII hex digits from an 8 bit value
void get_ascii_hex(char val, unsigned char* digits) {
	
	unsigned char i;
	for (i = 0; i < 2; i++) {
	
		// get the actual value of the digit
		digits[i] = (unsigned char)((val >> (4 * i)) & 0x0F);
		
		// get the ASCII of the value - see ASCII table to see how this works
		digits[i] += (digits[i] < 10) ? 48 : 87;
	}

	return;
}

// advance the sending state machine - called when transmitting data
void transmit_char(void) {
	
	if (send_state == SEND_0) {

		// send a '0' if we're at the start
		SCI1DRL = '0';
		send_state = SEND_x;

	} else if (send_state == SEND_x) {
	
		// send an 'x' if it's after a '0'
		SCI1DRL = 'x';
		send_state = SEND_DIGIT_0;

	} else if (send_state == SEND_DIGIT_0) {

		// compute the digits to send
		get_ascii_hex(send_stack[send_stack_pos], data_digits_ascii);

		// send the first digit
		SCI1DRL = data_digits_ascii[0];
		send_state = SEND_DIGIT_1;

	} else if (send_state == SEND_DIGIT_1) {

		// send the second digit
		SCI1DRL = data_digits_ascii[1];
		send_state = SEND_TAIL_MSG;

	} else if (send_state == SEND_TAIL_MSG) {

		// if we're at the end, switch state
		if (tail_msg[tail_msg_pos] == '\0') {

			tail_msg_pos = 0;
			send_stack_pos--;
			send_state = SEND_0;

			// also check if we should disable transmission interrupts
			if (send_stack_pos == -1) {
				SCI1CR1 &= ~(0x80);
			}
		} else {
			
			// otherwise, send the message data
			SCI1DRL = tail_msg[tail_msg_pos];
			tail_msg_pos++;
		}
	}
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
		if (send_stack_pos < SEND_STACK_SIZE - 1) {
			send_stack[send_stack_pos] = data_received;
			send_stack_pos++;
			// we have data now, so enable transmission interrupts:
			SCI1CR1 |= 0x80;
		}
	} 
	
	// if a character is ready to send, send one off the stack
	if (SCI1SR1 & 0x40 && send_stack_pos >= 0) {
		transmit_char();
	}

	return;
}
