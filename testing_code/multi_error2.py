# This file contains multiple errors:
#   - An invalid variable on line 8 (b is used without being defined)
#   - An invalid variable on line 8 (c is used without being defined)
#   - An invalid variable on line 9 (b is used without being defined)
#   - An invalid variable on line 9 (c is used without being defined)
#   - An invalid token ("$") on line 10
#   - A missing colon after the if statement on line 11
a = b + c
d = b * c
d = d $ a
if d > 100
    a = d
