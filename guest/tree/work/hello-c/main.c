#include <stdio.h>

int main(void) {
    printf("こんにちは、C の世界\n");

    /* 変数と計算 */
    int a = 6, b = 7;
    printf("%d かける %d は %d\n", a, b, a * b);

    /* 繰り返し */
    for (int i = 1; i <= 5; i++) {
        printf("%d の2乗は %d\n", i, i * i);
    }
    return 0;
}
