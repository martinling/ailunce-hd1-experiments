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
.equ UART_MODULE_CLOCK,	63336800 // Dunno why, empirically determined
.equ BAUD_RATE,		115200
.equ BAUD_CLOCK_FREQ,	(BAUD_RATE * 16)
.equ BAUD_DIVISOR,	(UART_MODULE_CLOCK / BAUD_CLOCK_FREQ)
// Fine tuning value is in units of 1/32, added to the integer divisor.
// Ideal divisor is (63.3368MHz / (16 * 115.2kHz)) = 34.3624
// Closest we can get is 34 + 12/32 = 34.375
.equ BAUD_FINE_TUNE,	12
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
// and the same in the CRC32 table.
.equ VECTOR_COUNT,	0x100
.equ VECTOR_TABLE_SIZE,	(VECTOR_COUNT * 4)
.equ CRC32_TABLE_SIZE,	0x100 * 4

// Calculate required addresses.

// Vector table is placed at load address, followed by CRC32 table.
.equ CRC32_TABLE_ADDR,	(LOAD_ADDRESS + VECTOR_TABLE_SIZE)
// Entry point is after CRC32 table, add 1 to set LSB to select thumb mode.
.equ ENTRY_POINT,	(CRC32_TABLE_ADDR + CRC32_TABLE_SIZE + 1)

// Vector table
vectors:
	.word STACK_INITIAL
	.word ENTRY_POINT
	// Use the entry point for all interrupt handlers too.
	.rept (VECTOR_COUNT - 2)
	.word ENTRY_POINT
	.endr

// CRC32 table
crc32_table:
	.word 0x00000000
	.word 0x77073096
	.word 0xEE0E612C
	.word 0x990951BA
	.word 0x076DC419
	.word 0x706AF48F
	.word 0xE963A535
	.word 0x9E6495A3
	.word 0x0EDB8832
	.word 0x79DCB8A4
	.word 0xE0D5E91E
	.word 0x97D2D988
	.word 0x09B64C2B
	.word 0x7EB17CBD
	.word 0xE7B82D07
	.word 0x90BF1D91
	.word 0x1DB71064
	.word 0x6AB020F2
	.word 0xF3B97148
	.word 0x84BE41DE
	.word 0x1ADAD47D
	.word 0x6DDDE4EB
	.word 0xF4D4B551
	.word 0x83D385C7
	.word 0x136C9856
	.word 0x646BA8C0
	.word 0xFD62F97A
	.word 0x8A65C9EC
	.word 0x14015C4F
	.word 0x63066CD9
	.word 0xFA0F3D63
	.word 0x8D080DF5
	.word 0x3B6E20C8
	.word 0x4C69105E
	.word 0xD56041E4
	.word 0xA2677172
	.word 0x3C03E4D1
	.word 0x4B04D447
	.word 0xD20D85FD
	.word 0xA50AB56B
	.word 0x35B5A8FA
	.word 0x42B2986C
	.word 0xDBBBC9D6
	.word 0xACBCF940
	.word 0x32D86CE3
	.word 0x45DF5C75
	.word 0xDCD60DCF
	.word 0xABD13D59
	.word 0x26D930AC
	.word 0x51DE003A
	.word 0xC8D75180
	.word 0xBFD06116
	.word 0x21B4F4B5
	.word 0x56B3C423
	.word 0xCFBA9599
	.word 0xB8BDA50F
	.word 0x2802B89E
	.word 0x5F058808
	.word 0xC60CD9B2
	.word 0xB10BE924
	.word 0x2F6F7C87
	.word 0x58684C11
	.word 0xC1611DAB
	.word 0xB6662D3D
	.word 0x76DC4190
	.word 0x01DB7106
	.word 0x98D220BC
	.word 0xEFD5102A
	.word 0x71B18589
	.word 0x06B6B51F
	.word 0x9FBFE4A5
	.word 0xE8B8D433
	.word 0x7807C9A2
	.word 0x0F00F934
	.word 0x9609A88E
	.word 0xE10E9818
	.word 0x7F6A0DBB
	.word 0x086D3D2D
	.word 0x91646C97
	.word 0xE6635C01
	.word 0x6B6B51F4
	.word 0x1C6C6162
	.word 0x856530D8
	.word 0xF262004E
	.word 0x6C0695ED
	.word 0x1B01A57B
	.word 0x8208F4C1
	.word 0xF50FC457
	.word 0x65B0D9C6
	.word 0x12B7E950
	.word 0x8BBEB8EA
	.word 0xFCB9887C
	.word 0x62DD1DDF
	.word 0x15DA2D49
	.word 0x8CD37CF3
	.word 0xFBD44C65
	.word 0x4DB26158
	.word 0x3AB551CE
	.word 0xA3BC0074
	.word 0xD4BB30E2
	.word 0x4ADFA541
	.word 0x3DD895D7
	.word 0xA4D1C46D
	.word 0xD3D6F4FB
	.word 0x4369E96A
	.word 0x346ED9FC
	.word 0xAD678846
	.word 0xDA60B8D0
	.word 0x44042D73
	.word 0x33031DE5
	.word 0xAA0A4C5F
	.word 0xDD0D7CC9
	.word 0x5005713C
	.word 0x270241AA
	.word 0xBE0B1010
	.word 0xC90C2086
	.word 0x5768B525
	.word 0x206F85B3
	.word 0xB966D409
	.word 0xCE61E49F
	.word 0x5EDEF90E
	.word 0x29D9C998
	.word 0xB0D09822
	.word 0xC7D7A8B4
	.word 0x59B33D17
	.word 0x2EB40D81
	.word 0xB7BD5C3B
	.word 0xC0BA6CAD
	.word 0xEDB88320
	.word 0x9ABFB3B6
	.word 0x03B6E20C
	.word 0x74B1D29A
	.word 0xEAD54739
	.word 0x9DD277AF
	.word 0x04DB2615
	.word 0x73DC1683
	.word 0xE3630B12
	.word 0x94643B84
	.word 0x0D6D6A3E
	.word 0x7A6A5AA8
	.word 0xE40ECF0B
	.word 0x9309FF9D
	.word 0x0A00AE27
	.word 0x7D079EB1
	.word 0xF00F9344
	.word 0x8708A3D2
	.word 0x1E01F268
	.word 0x6906C2FE
	.word 0xF762575D
	.word 0x806567CB
	.word 0x196C3671
	.word 0x6E6B06E7
	.word 0xFED41B76
	.word 0x89D32BE0
	.word 0x10DA7A5A
	.word 0x67DD4ACC
	.word 0xF9B9DF6F
	.word 0x8EBEEFF9
	.word 0x17B7BE43
	.word 0x60B08ED5
	.word 0xD6D6A3E8
	.word 0xA1D1937E
	.word 0x38D8C2C4
	.word 0x4FDFF252
	.word 0xD1BB67F1
	.word 0xA6BC5767
	.word 0x3FB506DD
	.word 0x48B2364B
	.word 0xD80D2BDA
	.word 0xAF0A1B4C
	.word 0x36034AF6
	.word 0x41047A60
	.word 0xDF60EFC3
	.word 0xA867DF55
	.word 0x316E8EEF
	.word 0x4669BE79
	.word 0xCB61B38C
	.word 0xBC66831A
	.word 0x256FD2A0
	.word 0x5268E236
	.word 0xCC0C7795
	.word 0xBB0B4703
	.word 0x220216B9
	.word 0x5505262F
	.word 0xC5BA3BBE
	.word 0xB2BD0B28
	.word 0x2BB45A92
	.word 0x5CB36A04
	.word 0xC2D7FFA7
	.word 0xB5D0CF31
	.word 0x2CD99E8B
	.word 0x5BDEAE1D
	.word 0x9B64C2B0
	.word 0xEC63F226
	.word 0x756AA39C
	.word 0x026D930A
	.word 0x9C0906A9
	.word 0xEB0E363F
	.word 0x72076785
	.word 0x05005713
	.word 0x95BF4A82
	.word 0xE2B87A14
	.word 0x7BB12BAE
	.word 0x0CB61B38
	.word 0x92D28E9B
	.word 0xE5D5BE0D
	.word 0x7CDCEFB7
	.word 0x0BDBDF21
	.word 0x86D3D2D4
	.word 0xF1D4E242
	.word 0x68DDB3F8
	.word 0x1FDA836E
	.word 0x81BE16CD
	.word 0xF6B9265B
	.word 0x6FB077E1
	.word 0x18B74777
	.word 0x88085AE6
	.word 0xFF0F6A70
	.word 0x66063BCA
	.word 0x11010B5C
	.word 0x8F659EFF
	.word 0xF862AE69
	.word 0x616BFFD3
	.word 0x166CCF45
	.word 0xA00AE278
	.word 0xD70DD2EE
	.word 0x4E048354
	.word 0x3903B3C2
	.word 0xA7672661
	.word 0xD06016F7
	.word 0x4969474D
	.word 0x3E6E77DB
	.word 0xAED16A4A
	.word 0xD9D65ADC
	.word 0x40DF0B66
	.word 0x37D83BF0
	.word 0xA9BCAE53
	.word 0xDEBB9EC5
	.word 0x47B2CF7F
	.word 0x30B5FFE9
	.word 0xBDBDF21C
	.word 0xCABAC28A
	.word 0x53B39330
	.word 0x24B4A3A6
	.word 0xBAD03605
	.word 0xCDD70693
	.word 0x54DE5729
	.word 0x23D967BF
	.word 0xB3667A2E
	.word 0xC4614AB8
	.word 0x5D681B02
	.word 0x2A6F2B94
	.word 0xB40BBE37
	.word 0xC30C8EA1
	.word 0x5A05DF1B
	.word 0x2D02EF8D

// Name some registers.
led_base .req r7
led_bit .req r6
uart_base .req r5
flash_ptr .req r4
crc .req r3

// Entry point (offset should now be 0x800).
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

block_start:
	// Initialise CRC
	ldr crc, =0xFFFFFFFF			// crc = 0xFFFFFFFF

	// Write sync word to UART, and include in CRC.
	mov r0, #'D				// r0 = 'D'
	bl update_crc_and_send			// update_crc_and_send(r0)
	mov r0, #'U				// r0 = 'U'
	bl update_crc_and_send			// update_crc_and_send(r0)
	mov r0, #'M				// r0 = 'M'
	bl update_crc_and_send			// update_crc_and_send(r0)
	mov r0, #'P				// r0 = 'P'
	bl update_crc_and_send			// update_crc_and_send(r0)

	// Write flash address to UART, and include in CRC.
	lsr r0, flash_ptr, #0			// r0 = flash_ptr >> 0
	bl update_crc_and_send			// update_crc_and_send(r0)
	lsr r0, flash_ptr, #8			// r0 = flash_ptr >> 8
	bl update_crc_and_send			// update_crc_and_send(r0)
	lsr r0, flash_ptr, #16			// r0 = flash_ptr >> 16
	bl update_crc_and_send			// update_crc_and_send(r0)
	lsr r0, flash_ptr, #24			// r0 = flash_ptr >> 24
	bl update_crc_and_send			// update_crc_and_send(r0)

byte_start:
	// Read next byte from flash.
	ldrb r0, [flash_ptr]			// r0 = *flash_ptr

	// Write byte to UART, and include in CRC.
	bl update_crc_and_send			// update_crc_and_send(r0)

	// Increment pointer
	add flash_ptr, #1			// flash_ptr += 1

	// If not at end of 1K block, handle next byte.
	lsl r0, flash_ptr, #23			// r0 = flash_ptr << 23
	bne byte_start				// if r0 != 0: goto byte_start

	// Otherwise, send CRC.
	lsr r0, crc, #0				// r0 = crc >> 0
	bl uart_write				// uart_write(r0)
	lsr r0, crc, #8				// r0 = crc >> 8
	bl uart_write				// uart_write(r0)
	lsr r0, crc, #16			// r0 = crc >> 16
	bl uart_write				// uart_write(r0)
	lsr r0, crc, #24			// r0 = crc >> 24
	bl uart_write				// uart_write(r0)

	// Stop if at end of flash.
	ldr r0, =FLASH_END			// r0 = FLASH_END
	cmp flash_ptr, r0			// if flash_ptr == r0:
	beq dump_start				//	goto dump_start

	// Otherwise, start next block.
	b block_start				// goto block_start

update_crc_and_send:
	// Update CRC with byte in bottom of r0, then fall through to uart_write.
	uxtb r0, r0				// r0 &= 0xFF
	uxtb r1, crc				// r1 = crc & 0xFF
	eor r1, r0				// r1 ^= r0
	ldr r2, =CRC32_TABLE_ADDR		// r2 = CRC32_TABLE_ADDR
	ldr r1, [r2, r1]			// r1 = r2[r1]
	lsr r2, crc, #8				// r2 = crc >> 8
	eor r1, r2				// r1 ^= r2
	mvn crc, r1				// crc = ~r1

uart_write:
	// Write byte in r0 to UART.

check_ready:
	// Read UART status and loop until ready for TX
	ldrb r1, [uart_base, #UART_S1]		// r1 = *(uart_base + UART_S1)
	lsr r1, #8				// r1 >>= 8, carry = r1[7]
	bcc check_ready				// if !carry: goto check_ready

	// Write to UART
	strb r0, [uart_base, #UART_D]		// *(uart_base + UART_D) = r0

check_complete:
	// Read UART status and loop until TX complete
	ldrb r1, [uart_base, #UART_S1]		// r1 = *(uart_base + UART_S1)
	lsr r1, #7				// r1 >>= 7, carry = r1[6]
	bcc check_complete			// if !carry: goto check_complete

	bx lr					// return

constants:
	// Assembler will put literal pool here.
