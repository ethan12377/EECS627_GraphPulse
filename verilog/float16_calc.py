import numpy as np
import random

def float16_calc(equation):
    ops = equation.split(' ')
    opA = int(ops[0], 16)
    op = ops[1]
    opB = int(ops[2], 16)
    opA_float16 = np.uint16(opA).view(np.float16)
    opB_float16 = np.uint16(opB).view(np.float16)
    float16_result = np.float16(0)
    if op == '+':
        float16_result = opA_float16 + opB_float16
    elif op == '-':
        float16_result = opA_float16 - opB_float16
    elif op == '*':
        float16_result = opA_float16 * opB_float16
    elif op == '/':
        float16_result = opA_float16 / opB_float16
    hex_result = hex(float16_result.view(np.uint16))
    # print('float result = ' + str(float16_result))
    # print('hex result = ' + str(hex_result))
    return str(hex_result)[2:].zfill(4)

def float16_calc_all(ops_filename, output_filename):
    fi = open(ops_filename, 'r')
    fo = open(output_filename, 'w')
    all_ops = fi.readlines()
    for line in all_ops:
        ops = line.split(' ')
        op1 = ops[0]
        op2 = ops[1]
        add_result = float16_calc(op1 + ' + ' + op2)
        sub_result = float16_calc(op1 + ' - ' + op2)
        mul_result = float16_calc(op1 + ' * ' + op2)
        div_result = float16_calc(op1 + ' / ' + op2)
        fo.write("opA = %s  opB = %s  add = %s  sub = %s  mul = %s  div = %s\n"%(op1, op2, add_result, sub_result, mul_result, div_result))
    fi.close()
    fo.close()

def gen_rand_ops(num_of_ops, filename):
    with open(filename, 'w') as f:
        for i in range(0, num_of_ops):
            op1_int = random.randint(1, 65536)
            op2_int = random.randint(1, 65536)
            while (op1_int in range(0x7c00, 0x8000) or op1_int in range(0xfbff, 0xffff + 1)): # prevent op1 from generating an overflow value
                op1_int = random.randint(1, 65536)
            while (op2_int in range(0x7c00, 0x8000) or op2_int in range(0xfbff, 0xffff + 1)): # prevent op1 from generating an overflow value
                op2_int = random.randint(1, 65536)
            op1 = hex(op1_int)[2:].zfill(4)
            op2 = hex(op2_int)[2:].zfill(4)
            f.write(op1 + ' ' + op2 + ' \n')

def main():
    gen_rand_ops(10000, 'fp_rand_ops.txt')
    float16_calc_all('fp_rand_ops.txt', 'fp_results_python.txt')

if __name__ == '__main__':
    main()