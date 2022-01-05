TOOLCHAIN ?= arm-none-eabi

all: hd1_blinky.elf hd1_blinky.bin hd1_dumpy.elf hd1_dumpy.bin

%.bin: %.elf
	$(TOOLCHAIN)-objcopy $< -Obinary $@

%.elf: %.s
	$(TOOLCHAIN)-as $< -o $@
