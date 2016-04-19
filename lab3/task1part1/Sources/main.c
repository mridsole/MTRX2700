/* ********************************************************************************
	MTRX2700 Lab 3
	TASK 1 PART 1: "Analog Input"
	GROUP: ??
	MEMBERS: ???
	DESCRIPTION: does a thing
	MODIFIED: yer
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

	// ATD0CTL4: SRES8 SMP1 SMP0 PRS4 PRS3 PRS2 PRS1 PRS0
	// 			 1     1    1    0    0    0    0    0 	????
	ATD0CTL4 = 0xEB; // from lectures - figure this out

	// ATD0CTL5: SCAN = 0, MULT = 0, right justification
	// channel 7, one conversion, no scan
	ATD0CTL5 = 0x87;
}

// configure the LEDs - use them all
void config_LEDs(void) {

	DDRJ = 0xFF;
	DDRB = 0xFF;
	PTJ = 0x00;
}

// read data from the ADC and write it to the bits 

// returns an 8-bit value to write to the LEDs, given a number from 0-255
// (maps from 0-255 to 0x01, 0x03, 0x07, ... etc)
char LED_bar(unsigned char val) {

	unsigned int i = 0;

	// return inverse of arithmetic shift right of the i required for
	// val / (i * 29) = 0. ...
	for (i = 1; i <= 8; i++) {
		if (val < (i * 29)) {
			return ~((char)0x80 >> (unsigned char)(8 - i));
		}
	}
	
	// val >= 8 * 29
	return 0xFF;
}

void main_loop(void) {

	// test some shit
	*((char*)0x1001) = LED_bar((unsigned char)200);

	// get the data in - poll until it's ready
	while (!(ATD0STAT0 & 0x80)) {}

	// now read the data from channel 7
	// somedata = ATD0DR7L;

	// write transformed data to LEDs
	PORTB = LED_bar(ATD0DR7L);

	// clear the conversion complete flag (this should happen automatically?)
	ATD0STAT0 = 0x00;

}

void main(void) {
	
	config_ADC();
	
	// don't need these!
	// EnableInterrupts;
	
	// loop
	for(;;) {
		main_loop();
	} 
}
