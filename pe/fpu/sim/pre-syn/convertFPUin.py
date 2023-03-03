# converts binary output from FPU to decimal to compare with expected results
import convert
import sys
output = sys.argv[1]

fbin = open(output, 'r')
fdec = open("fpu_input.txt", "w")
for line in fbin:
    tokens = line.split('_')
#     print(tokens)
    if (tokens[0] == '00'):
        op = ' + '
    elif (tokens[0] == '01'):
        op = ' - '
    elif (tokens[0] == '10'):
        op = ' * '
    else:
        op = ' / '
    opA = convert.float16_to_dec(tokens[1])
    opB = convert.float16_to_dec(tokens[2])
    fdec.write(str(opA)+op+str(opB)+'\n')

fbin.close()
fdec.close()


