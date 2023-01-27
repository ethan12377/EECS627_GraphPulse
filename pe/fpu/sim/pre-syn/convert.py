import math
import random

def bfloat_to_dec(bits):
    sign = bits[0]
    # print(sign)
    exponent = bits[1:9]
    # print(exponent)
    mantissa = bits[9:]
    # print(mantissa)
    sign_dec = (-1)**int(sign)
    # print(sign_dec)
    exponent_dec = int(exponent, 2)
    exponent_dec = 2**(exponent_dec-127)
    # print(exponent_dec)
    mantissa_dec = int(mantissa, 2)
    mantissa_dec = 1 + (mantissa_dec * 2**-7)
    # print(mantissa_dec)
    dec = sign_dec * exponent_dec * mantissa_dec
    return dec

# test1 = bfloat_to_dec('0111111010011111')
# print("underflow1="+str(test1))
# test2 = bfloat_to_dec('0011111010000000')
# print("underflow2="+str(test2))
# test3 = bfloat_to_dec('0011110000000000')
# print("underflow3"+str(test3))
# test1 = bfloat_to_dec('0111111010000000')
# print("underflow4="+str(test1))
# test2 = bfloat_to_dec('0000000010000000')
# print("underflow5="+str(test2))
# test1 = bfloat_to_dec('0100000000001000')
# print("underflow6="+str(test1))
# print("multiply2="+str(test2))
# test2 = bfloat_to_dec('1001111001100000')
# print("multiply3="+str(test2))
# test2 = bfloat_to_dec('0111111010100000')
# print("multiply4="+str(test2))
# test2 = bfloat_to_dec('0100000001100000')
# print("multiply5="+str(test2))
# test2 = bfloat_to_dec('0011111100000111')
# print("subtract="+str(test2))
# test2 = bfloat_to_dec('0011111100000111')
# print("subtract="+str(test2))
# test2 = bfloat_to_dec('0111111101111111')
# print("largestnum="+str(test2))
# test2 = bfloat_to_dec('0000000010000000')
# print("smallestnum="+str(test2))

def dec_to_bfloat(num):
    print("num = "+str(num))
    if (num < 0):
        sign = 1
    else:
        sign = 0
    exponent = math.log2(abs(num))
    exponent = math.floor(exponent)
    mantissa = abs(num) / (2**exponent)
    mantissa = mantissa - 1

    # format exponent
    exponent = exponent + 127
    print("exponent = "+str(exponent))
    exponent = format(exponent, '08b')
    print("exponent = "+str(exponent))

    # format mantissa
    mantissa = mantissa * (2**7)
    mantissa = format(int(mantissa), '07b')
    print("mantissa = "+str(mantissa))

    binary = str(sign) + exponent + mantissa
    return binary

# test1 = dec_to_bfloat(1.06e38)
# print("scinottest="+str(test1))
# test2 = dec_to_bfloat(1)
# print("1="+str(test2))
