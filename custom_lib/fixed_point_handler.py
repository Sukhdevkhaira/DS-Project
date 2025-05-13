import numpy as np
from bitstring import Bits
from bitstring import BitArray


def convert_binary_number_to_2complement_binary_number(number, bit_width):
    temp_number = number

    if number.startswith('0b'):
        temp_number = number[-bit_width:]

    binary_number = ''.join(['1' if i == '0' else '0' for i in temp_number])
    last_bit = 1

    for i in range(bit_width):
        if(last_bit == 1):
            if(binary_number[bit_width - 1 - i] == '1'):
                binary_number = list(binary_number)
                binary_number[bit_width - 1 - i] = '0'
                binary_number = ''.join(binary_number)
                last_bit = 1
            else:
                binary_number = list(binary_number)
                binary_number[bit_width - 1 - i] = '1'
                binary_number = ''.join(binary_number)
                last_bit = 0

    return '0b' + binary_number

# def convert_binary_number_to_2complement_binary_number(number, bit_width):
#     """
#     Convert a binary number to its 2's complement representation
    
#     Args:
#         number (str): Binary number as a string (can include '0b' prefix)
#         bit_width (int): Desired bit width of the result
    
#     Returns:
#         str: 2's complement representation with '0b' prefix
#     """
#     # Remove '0b' prefix if present
#     if number.startswith('0b'):
#         number = number[2:]
    
#     # Take only the last bit_width bits
#     temp_number = number[-bit_width:]
    
#     # Pad with zeros if necessary
#     temp_number = temp_number.zfill(bit_width)
    
#     # Step 1: Flip all the bits (1's complement)
#     binary_number = ''.join(['1' if i == '0' else '0' for i in temp_number])
    
#     # Step 2: Add 1 by simulating binary addition
#     result = list(binary_number)
#     carry = 1  # We need to add 1
    
#     for i in range(bit_width - 1, -1, -1):
#         if carry == 0:
#             break  # No more carry, we're done
        
#         if result[i] == '1':
#             result[i] = '0'  # 1 + 1 = 0 with carry
#             carry = 1
#         else:
#             result[i] = '1'  # 0 + 1 = 1 with no carry
#             carry = 0
    
#     return '0b' + ''.join(result)


def convert_pos_int_to_binary(pos_number, bit_width):
    if pos_number < 0:
        # Convert negative numbers to their two's complement representation
        pos_number = (1 << bit_width) + pos_number

    # Format the number as a binary string with leading zeros
    return format(pos_number, f'0{bit_width}b')[-bit_width:]
    # if((bit_width % 4) != 0):
    #     return str(Bits(int=pos_number, length=bit_width))
    # else:
    #     temp = str(Bits(int=pos_number, length=bit_width + 1))
    #     return '0b' + temp[-(len(temp) - 3):]
        


def convert_pos_fraction_to_binary(pos_number, bit_width):
    binary_number = ''
    temp_number = pos_number

    for i in range(bit_width):
        x2_temp_number = temp_number * 2

        if(int(x2_temp_number) == 1):
            binary_number = binary_number + '1'
            temp_number = x2_temp_number - 1
        else:
            binary_number = binary_number + '0'
            temp_number = x2_temp_number

    return binary_number


def convert_pos_fixedpoint_to_binary(pos_number, bit_width, dot_position): # From dot position to the right is fraction
    pos_integer = int(pos_number)
    pos_fraction = pos_number - pos_integer

    bit_width_for_pos_integer = bit_width - dot_position
    bit_width_for_fraction = dot_position

    pos_integer_binary_number = convert_pos_int_to_binary(pos_integer, bit_width_for_pos_integer)
    pos_fraction_binary_number = convert_pos_fraction_to_binary(pos_fraction, bit_width_for_fraction)

    # print("pos_integer_binary_number: ", pos_integer_binary_number)
    # print("pos_fraction_binary_number: ", pos_fraction_binary_number)

    return pos_integer_binary_number + pos_fraction_binary_number


def convert_neg_fixedpoint_to_binary(neg_number, bit_width, dot_position): # From dot position to the right is fraction
    pos_integer = int(0 - neg_number)
    pos_fraction = 0 - neg_number - pos_integer

    bit_width_for_neg_integer = bit_width - dot_position
    bit_width_for_fraction = dot_position

    pos_integer_binary_number = convert_pos_int_to_binary(pos_integer, bit_width_for_neg_integer)
    pos_fraction_binary_number = convert_pos_fraction_to_binary(pos_fraction, bit_width_for_fraction)

    pos_binary_number = pos_integer_binary_number + pos_fraction_binary_number
    neg_binary_number = convert_binary_number_to_2complement_binary_number(pos_binary_number, bit_width)

    return neg_binary_number


def convert_fixedpoint_to_binary(number, bit_width, dot_position): # From dot position to the right is fraction
    if(number < 0):
        # print("neg")
        return convert_neg_fixedpoint_to_binary(number, bit_width, dot_position)
    else:
        # print("pos")
        return convert_pos_fixedpoint_to_binary(number, bit_width, dot_position)


def convert_binary_to_int(number):
    integer = BitArray(bin=number)
    integer = integer.int
    return integer


def convert_binary_to_uint(number):
    unsigned_integer = BitArray(bin=number)
    unsigned_integer = unsigned_integer.uint
    return unsigned_integer


def convert_binary_to_pos_float_fraction(number, bit_width):
    fraction = 0
    for i in range(bit_width):
        if(number[i] == '1'):
            fraction = fraction + 2**(- (i + 1))

    return fraction


def convert_binary_to_pos_fixedpoint(pos_number, bit_width, dot_position): # From dot position to the right is fraction
    bit_width_for_integer = bit_width - dot_position
    bit_width_for_fraction = dot_position

    pos_integer = pos_number[0:bit_width_for_integer + 2]
    pos_fraction = pos_number[-bit_width_for_fraction:]

    pos_integer = BitArray(bin=pos_integer)
    pos_integer = pos_integer.uint

    pos_fraction = convert_binary_to_pos_float_fraction(pos_fraction, bit_width_for_fraction)

    pos_fixedpoint = pos_integer + pos_fraction

    return pos_fixedpoint


def convert_binary_to_neg_fixedpoint(neg_number, bit_width, dot_position): # From dot position to the right is fraction
    pos_number = convert_binary_number_to_2complement_binary_number(neg_number, bit_width)

    bit_width_for_integer = bit_width - dot_position
    bit_width_for_fraction = dot_position

    pos_integer = pos_number[0:bit_width_for_integer + 2]
    pos_fraction = pos_number[-bit_width_for_fraction:]

    pos_integer = BitArray(bin=pos_integer)
    pos_integer = pos_integer.uint

    pos_fraction = convert_binary_to_pos_float_fraction(pos_fraction, bit_width_for_fraction)

    pos_fixedpoint = pos_integer + pos_fraction

    return 0 - pos_fixedpoint

def convert_binary_to_fixedpoint(number, bit_width, dot_position): # From dot position to the right is fraction
    if(number[2] == '1'): # 0b1...
        return convert_binary_to_neg_fixedpoint(number, bit_width, dot_position)
    else: # 0b0...
        return convert_binary_to_pos_fixedpoint(number, bit_width, dot_position)


def binary_to_hex(binary_str, bit_width):
    num = binary_str
    if num.startswith('0b'):
        num = num[-bit_width:]

    # Convert binary to integer
    integer_value = int(num, 2)
    # Convert integer to hexadecimal and format it according to bit_width
    hex_value = hex(integer_value)[2:].zfill(bit_width // 4)
    return "0x" + hex_value


def int_to_binary(number, bit_width):
    if number < 0:
        # Convert negative numbers to their two's complement representation
        number = (1 << bit_width) + number

    # Format the number as a binary string with leading zeros
    return format(number, f'0{bit_width}b')[-bit_width:]

def hex_to_bin_fixed_width(hex_str, bit_width):
    """Convert hex string to binary string with a fixed bit width."""
    # Convert hex to integer
    value = int(hex_str, 16)
    
    # Format integer to binary string with leading zeros to match bit width
    binary_str = format(value, f'0{bit_width}b')
    
    return '0b' + binary_str

def hex_to_fixedpoint(hex_number,bit_width,fraction_width):
    binary_number = hex_to_bin_fixed_width(hex_number,bit_width)
    fixed_point_number = convert_binary_to_fixedpoint(binary_number, bit_width, fraction_width)
    return fixed_point_number



# def int_to_binary(number, bit_width):
#     if(number < 0):
#         pos_number = 0 - number
#         pos_binary_number = convert_pos_int_to_binary(pos_number=pos_number, bit_width=bit_width)

#         print("pos_binary_number: ", pos_binary_number)
#         print("2's complement: ", convert_binary_number_to_2complement_binary_number(number=pos_binary_number, bit_width=bit_width))

#         return convert_binary_number_to_2complement_binary_number(number=pos_binary_number, bit_width=bit_width)
#     else:
#         return convert_pos_int_to_binary(number, bit_width)