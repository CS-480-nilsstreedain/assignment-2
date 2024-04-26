#include <stdio.h>
int main() {
double n;
double f0;
double f1;
double i;
double fi;
double f;

/* Begin program */

n = 6;
f0 = 0;
f1 = 1;
i = 0;
while (1) {
fi = f0 + f1;
f0 = f1;
f1 = fi;
i = i + 1;
if (i >= n) {
break;
}
}
f = f0;

/* End program */

printf("n: %lf\n", n);
printf("f0: %lf\n", f0);
printf("f1: %lf\n", f1);
printf("i: %lf\n", i);
printf("fi: %lf\n", fi);
printf("f: %lf\n", f);
}
