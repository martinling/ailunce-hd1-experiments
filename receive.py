from serial import Serial
from crc32 import crc32
import sys

portname, filename = sys.argv[1:]

baud_rate = 115200
flash_size = 0x80000
block_size = 0x400
sync_word = b'DUMP'

port = Serial(portname, baud_rate)
output = open(filename, 'wb')

total_blocks = flash_size / block_size
received_blocks = 0

while received_blocks < total_blocks:

    # Look for sync word
    last_4_bytes = b'xxxx'
    while last_4_bytes != sync_word:
        last_4_bytes = last_4_bytes[1:4] + port.read(1)

    # Read flash address
    flash_addr_bytes = port.read(4)
    flash_addr = int.from_bytes(flash_addr_bytes, 'little')

    # Read data
    data = port.read(block_size)

    # Read CRC
    crc = int.from_bytes(port.read(4), 'little')

    # Calculate expected CRC
    expected_crc = crc32(sync_word + flash_addr_bytes + data)

    # Ignore block if CRC doesn't match
    if crc != expected_crc:
        print("Bad block received for address %X" % flash_addr)
        continue

    # Otherwise, add to output file
    received_blocks += 1
    print("Block received for address %X, %d/%d blocks received"
        % (flash_addr, received_blocks, total_blocks))

    output.seek(flash_addr)
    output.write(data)

print("All blocks received")
output.close()
