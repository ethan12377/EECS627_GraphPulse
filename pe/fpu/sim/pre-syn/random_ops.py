import random
import decimal

NUM_OPS = 50
ops = ['00','01','10','11']
for i in range(NUM_OPS):
    xSign = str(random.randint(0,1))
    ySign = str(random.randint(0,1))
    xExp = random.randint(0,30)
    yExp = format(random.randint(max(xExp-8,0),min(xExp+8,30)), '05b')
    xExp = format(xExp, '05b')
    xMant = format(random.randint(0,1023), '010b')
    yMant = format(random.randint(0,1023), '010b')
    op = random.choice(ops)
    print(op+'_'+xSign+xExp+xMant+'_'+ySign+yExp+yMant)
print('10_1111111111111111_0011111101000000')
