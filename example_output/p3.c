#include <stdio.h>
int main() {
double a;
double b;
double x;
double y;
double z;

/* Begin program */

a = 1;
b = 0;
x = 7;
if (a) {
x = 5;
if (b) {
y = 4;
} else {
y = 2;
}
}
z = (x * 3 * 7) / y;
if (z > 10) {
y = 5;
}

/* End program */

printf("a: %lf\n", a);
printf("b: %lf\n", b);
printf("x: %lf\n", x);
printf("y: %lf\n", y);
printf("z: %lf\n", z);
}
