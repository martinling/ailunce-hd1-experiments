/*

Blinky for Ailunce HD1

Martin Ling, Jan 2022

This file is placed into the public domain.

*/

// Load address
.equ LOAD_ADDRESS,	0x4000

// Which pin the LED is on
.equ LED_PORT,		1	// Port A is 0, Port B is 1, etc.
.equ LED_PIN,		18

// System clock gating register
.equ SIM_SCGC5,		0x40048038
.equ LED_SCGC5,		(1 << (9 + LED_PORT))

// Port control register
.equ PORT_PCR_BASE,	0x40049000
.equ LED_PORT_PCR,	(PORT_PCR_BASE + (0x1000 * LED_PORT) + (4 * LED_PIN))
.equ PCR_GPIO,		(1 << 8)	

// GPIO registers
.equ GPIO_BASE,		0x400FF000
.equ LED_GPIO_BASE,	(GPIO_BASE + (0x40 * LED_PORT))
.equ LED_GPIO_PDDR,	(LED_GPIO_BASE + 0x14)
.equ LED_GPIO_PTOR,	(LED_GPIO_BASE + 0x0C)
.equ LED_GPIO_BIT,	(1 << LED_PIN)

.equ CLOCK_FREQ,	120000000

// Delay loop takes 4 cycles per iteration
.equ SECOND,		CLOCK_FREQ
.equ DELAY_CYCLES,	(SECOND / 2)
.equ DELAY_COUNT,	(DELAY_CYCLES / 4)

// Initial stack pointer (doesn't matter, use same as existing firmware)
.equ STACK_INITIAL,	0x2000FEF0

// There are 256 entries in the vector table (1024 bytes)
.equ VECTOR_COUNT,	0x100
.equ TABLE_SIZE,	(VECTOR_COUNT * 4)

// Calculate entry point:
// - Image is placed at load address
// - Code begins after vector table
// - Add 1 to set LSB to select Thumb mode
.equ ENTRY_POINT,	(LOAD_ADDRESS + TABLE_SIZE + 1)

// Vector table
vectors:
	.word STACK_INITIAL
	.word ENTRY_POINT
	// Use the entry point for all interrupt handlers too.
	.rept (VECTOR_COUNT - 2)
	.word ENTRY_POINT
	.endr

// Entry point (offset should now be 0x400).
.thumb_func
entry_point:
	// Enable clock to LED port.
	ldr r0, =SIM_SCGC5	// r0 = SIM_SCGC5
	ldr r1, [r0]		// r1 = *r0
	ldr r2, =LED_SCGC5	// r2 = LED_SCGC5
	orr r1, r2		// r1 |= r2
	str r1, [r0]		// *r0 = r1

	// Set LED pin to GPIO.
	ldr r0, =LED_PORT_PCR	// r0 = LED_PORT_PCR
	ldr r1, =PCR_GPIO	// r1 = PCR_GPIO
	str r1, [r0]		// *r0 = r1

	// Set LED pin to output.
	ldr r0, =LED_GPIO_PDDR	// r0 = LED_GPIO_PDDR
	ldr r1, [r0]		// r1 = *r0
	ldr r2, =LED_GPIO_BIT	// r2 = LED_GPIO_BIT
	orr r1, r2		// r1 |= r2
	str r1, [r0]		// *r0 = r1

	// Load r0 with toggle register address
	ldr r0, =LED_GPIO_PTOR	// r0 = LED_GPIO_PTOR

loop:
	// Start delay loop
	ldr r1, =DELAY_COUNT	// r1 = DELAY_COUNT
delay:
	sub r1, #1		// r1 -= 1
	bmi delay		// if r1 < 0: goto delay

	// Toggle LED
	str r2, [r0]		// *r0 = r2

	b loop			// goto loop

constants:
	// Assembler will put literal pool here.
