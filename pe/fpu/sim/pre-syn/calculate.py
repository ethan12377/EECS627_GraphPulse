# takes input.txt and produces output.txt
import sys
input_file = sys.argv[1]
output_file = sys.argv[2]

fin = open(input_file, 'r')
fout = open(output_file, 'w')
for line in fin:
    res = eval(line)
    if (res>3.38e+38):
        fout.write('OVERFLOW 3.402823669209385e+38\n')
    elif (res<-3.38e+38):
        # note: if result is <-3.38e+38 for subtraction operations, 
        # fpu will raise underflow flag instead, but compare.py will 
        # ignore the result either way
        fout.write('OVERFLOW -3.402823669209385e+38\n')
    else:
        fout.write(str(res)+'\n')
fin.close()
fout.close()
