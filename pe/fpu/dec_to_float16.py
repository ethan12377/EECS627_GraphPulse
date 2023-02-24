
import numpy as np

while True:
    # Prompt the user to enter a decimal number
    num = input("Enter a decimal number (or 'q' to quit): ")

    # Check if the user wants to quit
    if num.lower() == 'q':
        break

    # Convert the input number to a float16 number
    try:
        num = np.float16(num)
        # Convert the float16 number to its binary representation
        binary = np.binary_repr(num.view('H'), width=16)
        # Insert underscores between the sign, exponent, and mantissa bits
        binary = f"{binary[0]}_{binary[1:6]}_{binary[6:]}"
        # Convert the float16 number back to decimal
        decimal = float(num)
    except ValueError:
        binary = None
        decimal = None

    # Print the binary and decimal representations
    if binary is not None:
        print(f"Binary representation: {binary}")
        print(f"Decimal representation: {decimal}")
    else:
        print("Invalid input")
