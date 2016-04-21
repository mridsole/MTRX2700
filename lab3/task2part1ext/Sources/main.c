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

// 7seg lookup table
char seg_lookup[] = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 
	0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71 };

// with a prescaler of 128, 0.2 seconds is 37500
#define DISP_INTERVAL 37500

// whether to display decimal or to display hex
enum { DISPLAY_DEC, DISPLAY_HEX } display_mode = DISPLAY_DEC;

// the current display interval scaling factor (1 to 10)
unsigned char disp_interval_scale = 1;

// count from 0 up to disp_interval_scale
unsigned char disp_interval_count = 0;

// the number we're displaying on 7segs
unsigned int disp_num = 0x8AFE;


// a small delay (not very accurate!)
void delay_small(void) {
	
	// use inline assembly here to ensure that the delay
	// does not depend on compiler optimisation settings
	__asm {
			PSHX	
			LDX		#300
		delay_small_L:
			DEX
			BNE		delay_small_L
			PULX
	};
}

// configure the serial communications interface
void config_SCI(void) {

	// configure baud rate (see the previous lab)
	SCI1BDH = 0x00;
	SCI1BDL = 0x9C;

	// control registers - M = 0, WAKE = 0, no parity, use receive interrupts
	SCI1CR1 = 0x00;
	SCI1CR2 = 0x2C;

	return;
}

// configure the enhanced capture timer system
void config_ECT(void) {

	TCTL1 = 0x00;
	TIOS = 0x10;
	TSCR1 = 0x80;

	// prescaler 128
	TSCR2 = 0x07;
	TIE = 0x10;
}

// configure the 7 segment display
void config_7seg(void) {
	
	DDRP = 0xFF; // seg selection port
	DDRB = 0xFF; // data bus
}

// clear each 7seg (used to avoid ghosting)
void clear_7seg(void) {

	PTP = 0x00;
	PORTB = 0x00;
}

// write to the given 7 seg display
// choose display with seg from 0 to 3
void write_7seg(unsigned char seg, char data) {

	PTP = ~(0x01 << seg) & 0x0F;
	PORTB = data;
}

// get the decimal digits
void get_digits_dec(unsigned int val, char* digits) {
	
	unsigned int val_div = val;
	unsigned char i;
	for (i = 0; i < 4; i++) {
		digits[i] = val_div % 10;
		val_div = val_div / 10;
	}

	return;
}

// get the hex digits
void get_digits_hex(unsigned int val, char* digits) {
	
	// much simpler - just shift four times
	unsigned char i;
	for (i = 0; i < 4; i++) {
		digits[i] = (unsigned char)((val >> (4 * i)) & 0x0F);
	}

	return;
}

void main_loop(void) {

	unsigned char i = 0;
	
	// store the digits 
	char digits[4];

	if (display_mode == DISPLAY_DEC) {
		get_digits_dec(disp_num, digits);
	} else if (display_mode == DISPLAY_HEX) {
		get_digits_hex(disp_num, digits);
	}

	// display on the 7 segs
	// assuming digits is in reverse order
	for (i = 0; i < 4; i++) {
		write_7seg(3 - i, digits[i]);
		delay_small();
		clear_7seg();
	}
}

void main(void) {

	unsigned char i = 0;
	
	// disable interrupts while configuring the SCI and ECT
	DisableInterrupts;
	config_SCI();
	config_ECT();
	config_7seg();
	EnableInterrupts;

	// clear all displays
	clear_7seg();

	// main loop
	for(;;) {
		main_loop();
	} 
}

// interrupt for receiving a character from the terminal
interrupt 21 void SCI1_ISR(void) {

	char received = SCI1DRL;
	char digit;
	
	// respond appropriately to the received character:

	// switch between hex and dec display as required
	if (received == 'h') { display_mode = DISPLAY_HEX; return; }
	else if (received == 'd') { display_mode = DISPLAY_DEC; return; }

	// handle digits - use the fact that ASCII numerals start at 48
	digit = received - 48;

	// if it's not a digit, return
	if (digit < 0 || digit > 9) { return; }

	// otherwise, set the appropriate scaling factor
	disp_interval_scale = digit + 1;
	
	return;
}

interrupt 12 void TC4_ISR(void) {

	// wait DISP_INTERVAL prescaled cycles
	TC4 = TCNT + DISP_INTERVAL;
	TFLG1 = 0x10;   // clear the channel 4 flag
	
	disp_interval_count++;
	if (disp_interval_count % disp_interval_scale == 0) {
		disp_num++;
		if (display_mode == DISPLAY_DEC && disp_num > 9999) {
			disp_num = 0;
		} // (hex will overflow naturally)
		disp_interval_count = 0;
	}
}
