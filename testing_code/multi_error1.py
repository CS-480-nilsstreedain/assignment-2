# This file contains multiple errors:
#   - An invalid token ("@") on line 5
#   - An invalid variable on line 6 (c is used without being defined)
#   - Invalid indentation on line 7
a = 1 @ 2
b = a * c
    d = b + 1
