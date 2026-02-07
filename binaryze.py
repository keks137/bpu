import sys, struct
# tool to convert output from matt's assembler to binary
with open('output.mc', 'rb') as f:
    for line in f:
        sys.stdout.buffer.write(struct.pack('>H', int(line.strip(), 2)))
