TOOLCHAIN ?= arm-none-eabi
SERIAL_PORT ?= /dev/ttyUSB0

all: hd1_blinky.elf hd1_blinky.bin hd1_dumpy.elf hd1_dumpy.bin

flash: hd1_dumpy.bin
	radio_tool --flash -i $< -d 0 -P $(SERIAL_PORT)

%.bin: %.elf
	$(TOOLCHAIN)-objcopy $< -Obinary $@

%.elf: %.s
	$(TOOLCHAIN)-as $< -o $@
