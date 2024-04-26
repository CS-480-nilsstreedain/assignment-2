#include <stdio.h>
int main() {
double a;
double b;
double c;
double x;

/* Begin program */

a = 0;
b = 0;
c = 1;
x = 16;
if (a == 1) {
x = x * 2;
} else if (a * b > 0) {
x = x * 4;
} else if (c != 0) {
x = x * 8;
} else {
x = 0;
}

/* End program */

printf("a: %lf\n", a);
printf("b: %lf\n", b);
printf("c: %lf\n", c);
printf("x: %lf\n", x);
}
