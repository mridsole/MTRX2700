/* ********************************************************************************
	MTRX2700 Lab 3
	TASK 1 PART 1: "Analog Input"
	GROUP: 5
	MEMBERS: John Sumskas, Justin Ko, Jasmine Chen, Jacqui Dielwart, David Rapisarda
	DESCRIPTION: Reads the voltage on pin PAD7, and displays the scaled value on the
		8 LEDs. 
	MODIFIED: 26/04/2016
******************************************************************************** */

#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */

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

// configure the LEDs - use them all
void config_LEDs(void) {

	DDRJ = 0xFF;
	DDRB = 0xFF;
	PTJ = 0x00;
}

// returns an 8-bit value to write to the LEDs, given a number from 0-255
// (maps from 0-255 to 0x01, 0x03, 0x07, ... etc)
char LED_bar(unsigned char val) {

	unsigned char val_div = val / (unsigned char)29;
	
	// if val > 29 * 8 this is our biggest option
	if (val_div == 8) { return 0xFF; }

	// return inverse of arithmetic shift right of the i required for
	// val / (i * 29) < 1
	return ~((char)0x80 >> (unsigned char)(7 - val_div));
}

void main_loop(void) {
	
	// initiate a conversion sequence
	// ATD0CTL5: SCAN = 0, MULT = 0, right justification
	// channel 7, one conversion, no scan
	ATD0CTL5 = 0x87;

	// get the data in - poll until it's ready
	while (!(ATD0STAT0 & 0x80)) {}

	// write transformed data to LEDs
	PORTB = LED_bar(ATD0DR0L);

	// clear the conversion complete flag (this should happen automatically?)
	ATD0STAT0 = 0x00;

}

void main(void) {
	
	config_ADC();
	config_LEDs();
	
	// don't need these!
	// EnableInterrupts;
	
	// do the thing
	for(;;) {
		main_loop();
	} 
}
