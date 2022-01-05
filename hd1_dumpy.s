/*

Flash dump for Ailunce HD1

Martin Ling, Jan 2022

This file is placed into the public domain.

*/

// Load address
.equ LOAD_ADDRESS,	0x4000

// End of flash
.equ FLASH_END,		0x80000

// Which pin the LED is on
.equ LED_PORT,		1	// Port A is 0, Port B is 1, etc.
.equ LED_PIN,		19

// Which pins the UART is on
.equ UART_PORT,		0
.equ UART_RX_PIN,	1
.equ UART_TX_PIN,	2

// Which UART to use
.equ UART_NUM,		0

// Clock frequency
.equ CLOCK_FREQ,	120000000

// System clock gating registers
.equ SIM_SCGC4,		0x40048034
.equ UART_SCGC4,	(1 << (10 + UART_NUM))
.equ SIM_SCGC5,		0x40048038
.equ LED_SCGC5,		(1 << (9 + LED_PORT))

// Port control register
.equ PORT_PCR_BASE,	0x40049000
.equ LED_PCR,		(PORT_PCR_BASE + (0x1000 * LED_PORT) + (4 * LED_PIN))
.equ UART_RX_PCR,	(PORT_PCR_BASE + (0x1000 * UART_PORT) + (4 * UART_RX_PIN))
.equ UART_TX_PCR,	(PORT_PCR_BASE + (0x1000 * UART_PORT) + (4 * UART_TX_PIN))
.equ PCR_GPIO,		(1 << 8)
.equ PCR_UART,		(1 << 9)

// GPIO registers
.equ GPIO_BASE,		0x400FF000
.equ GPIO_PDDR,		0x14
.equ GPIO_PSOR,		0x04
.equ GPIO_PCOR,		0x08
.equ GPIO_PTOR,		0x0C

.equ LED_GPIO_BASE,	(GPIO_BASE + (0x40 * LED_PORT))
.equ LED_GPIO_BIT,	(1 << LED_PIN)

// UART registers
.equ UART_BASE,		(0x4006A000 + (0x1000 * UART_NUM))
.equ UART_BDH,		0x00
.equ UART_BDL,		0x01
.equ UART_C1,		0x02
.equ UART_C2,		0x03
.equ UART_S1,		0x04
.equ UART_S2,		0x05
.equ UART_C3,		0x06
.equ UART_D,		0x07
.equ UART_C4,		0x0A

// UART settings
.equ BAUD_RATE,		115200
.equ BAUD_CLOCK_FREQ,	(BAUD_RATE * 16)
.equ BAUD_DIVISOR,	(CLOCK_FREQ / BAUD_CLOCK_FREQ)
// Fine tuning value is in units of 1/32, added to the integer divisor.
// Ideal divisor is (120MHz / (16 * 115.2kHz)) = 65.104166.
// Closest we can get is 65 + 3/32 = 65.09375, giving baud rate of 115218.43.
.equ BAUD_FINE_TUNE,	3
.equ UART_BDH_VAL,	(BAUD_DIVISOR >> 8)
.equ UART_BDL_VAL,	(BAUD_DIVISOR & 0xFF)
.equ UART_C1_VAL,	0
.equ UART_C2_VAL,	(1 << 3) // Enable transmit
.equ UART_C3_VAL,	0
.equ UART_C4_VAL,	BAUD_FINE_TUNE
.equ UART_TX_EMPTY_BIT,	(1 << 7)

// Delay loop takes 4 cycles per iteration
.equ SECOND,		CLOCK_FREQ
.equ DELAY_CYCLES,	(5 * SECOND)
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

// Name some registers.
led_base .req r7
led_bit .req r6
uart_base .req r5
flash_ptr .req r4
flash_end .req r3
uart_empty .req r2

// Entry point (offset should now be 0x400).
.thumb_func
entry_point:
	// Enable clock to LED port.
	ldr r0, =SIM_SCGC5			// r0 = SIM_SCGC5
	ldr r1, [r0]				// r1 = *r0
	ldr r2, =LED_SCGC5			// r2 = LED_SCGC5
	orr r1, r2				// r1 |= r2
	str r1, [r0]				// *r0 = r1

	// Set LED pin to GPIO.
	ldr r0, =LED_PCR			// r0 = LED_PCR
	ldr r1, =PCR_GPIO			// r1 = PCR_GPIO
	str r1, [r0]				// *r0 = r1

	// Set LED pin to output.
	ldr led_base, =LED_GPIO_BASE		// led_base = LED_GPIO_BASE
	ldr r0, [led_base]			// r0 = *led_base
	ldr led_bit, =LED_GPIO_BIT		// led_bit = LED_GPIO_BIT
	orr r0, led_bit				// r0 |= led_bit
	str r0, [led_base, #GPIO_PDDR]		// *(led_base + GPIO_PDDR) = r0

	// Enable clock to UART.
	ldr r0, =SIM_SCGC4			// r0 = SIM_SCGC4
	ldr r1, [r0]				// r1 = *r0
	ldr r2, =UART_SCGC4			// r2 = UART_SCGC4
	orr r1, r2				// r1 |= r2
	str r1, [r0]				// *r0 = r1

	// Set TX/RX pins to UART.
	ldr r0, =PCR_UART			// r0 = PCR_UART
	ldr r1, =UART_RX_PCR			// r1 = UART_RX_PCR
	ldr r2, =UART_TX_PCR			// r2 = UART_TX_PCR
	str r0, [r1]				// *r1 = r0
	str r0, [r2]				// *r2 = r0

	// Set UART baud rate.
	ldr uart_base, =UART_BASE		// uart_base = UART_BASE
	ldr r0, =UART_BDH_VAL			// r0 = UART_BDH_VAL
	strb r0, [uart_base, #UART_BDH]		// *(uart_base + UART_BDH) = r0
	ldr r0, =UART_BDL_VAL			// r0 = UART_BDL_VAL
	strb r0, [uart_base, #UART_BDL]		// *(uart_base + UART_BDL) = r0

	// Set other UART parameters.
	ldr r0, =UART_C1_VAL			// r0 = UART_C1_VAL
	strb r0, [uart_base, #UART_C1]		// *(uart_base + UART_C1) = r0
	ldr r0, =UART_C2_VAL			// r0 = UART_C2_VAL
	strb r0, [uart_base, #UART_C2]		// *(uart_base + UART_C2) = r0
	ldr r0, =UART_C3_VAL			// r0 = UART_C3_VAL
	strb r0, [uart_base, #UART_C3]		// *(uart_base + UART_C3) = r0
	ldr r0, =UART_C4_VAL			// r0 = UART_C4_VAL
	strb r0, [uart_base, #UART_C4]		// *(uart_base + UART_C4) = r0

	// Load flash end address.
	ldr flash_end, =FLASH_END		// flash_end = FLASH_END

	// Load mask used to check UART TX empty bit.
	ldr uart_empty, =UART_TX_EMPTY_BIT	// uart_empty = UART_TX_EMPTY_BIT

dump_start:
	// Set LED off.
	str led_bit, [led_base, #GPIO_PCOR]	// *(led_base + GPIO_PCOR) = led_bit

	// Start delay loop
	ldr r0, =DELAY_COUNT			// r0 = DELAY_COUNT
delay:
	sub r0, #1				// r0 -= 1
	bne delay				// if r0 != 0: goto delay

	// Set LED on.
	str led_bit, [led_base, #GPIO_PSOR]	// *(led_base + GPIO_PSOR) = led_bit

	// Set initial flash address
	mov flash_ptr, #0			// flash_ptr = 0

byte_start:
	// Read next byte from flash.
	ldrb r0, [flash_ptr]			// r0 = *flash_ptr

check_uart:
	// Read UART status and loop until ready for TX
	ldr r1, [uart_base, #UART_S1]		// r1 = *(uart_base + UART_S1)
	and r1, uart_empty			// r1 &= uart_empty
	beq check_uart				// if r1 == 0: goto check_uart

	// Write to UART
	strb r0, [uart_base, #UART_D]		// *(uart_base + UART_D) = r0

	// Increment pointer
	add flash_ptr, #1			// flash_ptr += 1

	// Stop if at end of flash.
	cmp flash_ptr, flash_end		// if flash_ptr == flash_end:
	beq dump_start				//	goto dump_start

	// Otherwise repeat for next byte.
	b byte_start				// goto byte_start

constants:
	// Assembler will put literal pool here.
