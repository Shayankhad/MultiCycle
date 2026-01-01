#include <stdio.h>

int main(void) {
    int a[10] = { 1,2,3,4,5,6,7,8,9,10 };
    int sum = 0;

    for (int i = 0; i < 10; i++) {
        sum += a[i];
    }

    printf("Sum = %d\n", sum);

    return 0;
}
