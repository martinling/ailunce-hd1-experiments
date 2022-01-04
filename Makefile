TOOLCHAIN ?= arm-none-eabi

all: hd1_blinky.elf hd1_blinky.bin

%.bin: %.elf
	$(TOOLCHAIN)-objcopy $< -Obinary $@

%.elf: %.s
	$(TOOLCHAIN)-as $< -o $@
