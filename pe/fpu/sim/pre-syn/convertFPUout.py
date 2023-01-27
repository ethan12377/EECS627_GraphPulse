# converts binary output from FPU to decimal to compare with expected results
import convert
import sys
output = sys.argv[1]

fbin = open(output, 'r')
fdec = open("fp_output_dec.txt", "w")
for line in fbin:
    tokens = line.split()
    # print(tokens)
    if (tokens[2] == '1'):
        fdec.write('UNDERFLOW ')
    if (tokens[3] == '1'):
        fdec.write('OVERFLOW ')
    elif (tokens[4] == '1'):
        fdec.write('INEXACT ')
    num = convert.bfloat_to_dec(tokens[1])
    fdec.write(str(num))
    fdec.write('\n')

fbin.close()
fdec.close()


