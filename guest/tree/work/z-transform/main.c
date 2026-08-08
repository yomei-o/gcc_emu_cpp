/* Z 変換と、正弦波を作る漸化式
 *
 * 正弦波の Z 変換は
 *
 *              z sin(w)
 *     H(z) = ----------------------
 *            z^2 - 2 z cos(w) + 1
 *
 * 分母を y に、分子を x に読み替えると、そのまま漸化式になる:
 *
 *     y[n] = 2 cos(w) y[n-1] - y[n-2] + sin(w) x[n-1]
 *
 * x に単位インパルス（最初だけ 1）を入れると、あとは足し算と
 * 掛け算だけで sin が出てくる。sin() は係数を決めるときに
 * 一度使うだけで、ループの中では一度も呼んでいない。
 */
#include <stdio.h>
#include <math.h>

int main(void) {
    const int N = 200;
    const double w = 2.0 * M_PI / 32.0;   /* 32 点で 1 周 */

    const double a1 = 2.0 * cos(w);       /* 係数はここで決まる */
    const double b1 = sin(w);

    double y1 = 0.0, y2 = 0.0;            /* y[n-1], y[n-2] */

    FILE* csv = fopen("wave.csv", "w");
    fprintf(csv, "n,recurrence,sin\n");

    for (int n = 0; n < N; n++) {
        double x1 = (n == 1) ? 1.0 : 0.0;         /* 単位インパルス */
        double y = a1 * y1 - y2 + b1 * x1;
        y2 = y1;
        y1 = y;

        /* 答え合わせ用に本物の sin も出す */
        fprintf(csv, "%d,%.9f,%.9f\n", n, y, sin(w * n));
    }
    fclose(csv);

    printf("wave.csv を書きました。\n");
    printf("recurrence と sin を重ねると、ぴったり同じ波になります。\n");
    return 0;
}
