#include <stdio.h>
int main() {
double pi;
double r;
double circle_area;
double circle_circum;
double sphere_vol;
double sphere_surf_area;

/* Begin program */

pi = 3.1415;
r = 8.0;
circle_area = pi * r * r;
circle_circum = pi * 2 * r;
sphere_vol = (4.0 / 3.0) * pi * r * r * r;
sphere_surf_area = 4 * pi * r * r;

/* End program */

printf("pi: %lf\n", pi);
printf("r: %lf\n", r);
printf("circle_area: %lf\n", circle_area);
printf("circle_circum: %lf\n", circle_circum);
printf("sphere_vol: %lf\n", sphere_vol);
printf("sphere_surf_area: %lf\n", sphere_surf_area);
}
