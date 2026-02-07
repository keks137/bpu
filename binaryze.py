import sys, struct
# tool to convert output from matt's assembler to binary
with open('output.mc', 'rb') as inf:
    with open('output.mcb','wb') as outf:
        for line in inf:
            outf.write(struct.pack('>H', int(line.strip(), 2)))
