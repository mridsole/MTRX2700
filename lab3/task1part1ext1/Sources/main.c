/* ********************************************************************************
	MTRX2700 Lab 3
	TASK 1 PART 1 EXTENSION 1: "Analog Input"
	GROUP: ??
	MEMBERS: ???
	DESCRIPTION: does a thing
	MODIFIED: yer
******************************************************************************** */

#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */

// 7 seg lookup table (just for numbers, that's all we need)
char seg_lookup[] = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F };

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

// configure the ADC subsystem
void config_ADC(void) {
	
	// configure by writing to the appropriate registers:

	// ATD0CTL2: ADPU AFFC AWAI ETRIGLE ETRIGP ETRIGE ASCIE ASCIF
	//			 1	  1	   0    ?       ?      0 (?)  0     0
	ATD0CTL2 = 0xC0;

	// ATD0CTL3: 0 S8C S4C S2C S1C FIFO FRZ1 FRZ0
	// 			 0 0   0   0   1   0    0    0
	ATD0CTL3 = 0x08;
	
	// ??? (!)
	// ATD0CTL4: SRES8 SMP1 SMP0 PRS4 PRS3 PRS2 PRS1 PRS0
	// 			 1     1    1    0    0    0    0    0 
	ATD0CTL4 = 0xEB; // from lectures - figure this out
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

// get the two decimal digits from the value (0.0 to 5.0) represented
// with an int from 0 to 255
// digits: pointer to digits to write to in memory (size 2)
void get_digits(unsigned char val, char* digits) {
	
	const unsigned int VAL_MAX = 255;
	const unsigned int VAL_DIV = VAL_MAX / 5;
	digits[0] = val / VAL_DIV;
	digits[1] = (val % VAL_DIV) / (VAL_DIV / 10);
}

void main_loop(void) {

	unsigned int i = 0;
	char digits[2];
	
	// initiate a conversion sequence
	// ATD0CTL5: SCAN = 0, MULT = 0, right justification
	// channel 7, one conversion, no scan
	ATD0CTL5 = 0x87;

	// get the data in - poll until it's ready
	while (!(ATD0STAT0 & 0x80)) {}

	// get the digits from the thing
	get_digits(ATD0DR0L, digits);
	
	// write the digits to the segs
	for (i = 0; i < 2; i++) {
		write_7seg(1 - i, seg_lookup[digits[i]]);
		delay_small();
		clear_7seg();
	}

	// clear the conversion complete flag (this should happen automatically?)
	ATD0STAT0 = 0x00;
}

void main(void) {
	
	config_ADC();
	config_7seg();
	
	// don't need these!
	// EnableInterrupts;
	
	// do the thing
	for(;;) {
		main_loop();
	} 
}
