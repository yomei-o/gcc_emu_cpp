/* ニュートン法
 *
 * f(x) = 0 を解きたいとき、適当な出発点から
 *
 *     x <- x - f(x) / f'(x)
 *
 * を繰り返す。接線が横軸と交わる点へ飛ぶ、という意味。
 * うまくいくと桁数が毎回およそ倍になる（2次収束）。
 */
#include <stdio.h>
#include <math.h>

/* sin(x) = 0.5 を解く。つまり f(x) = sin(x) - 0.5 の零点。*/
static double f(double x)  { return sin(x) - 0.5; }
static double df(double x) { return cos(x); }

int main(void) {
    const double answer = M_PI / 6;   /* 正解は 30 度 = π/6 */
    double x = 1.0;                   /* 出発点 */

    FILE* csv = fopen("newton.csv", "w");
    fprintf(csv, "step,x,error\n");

    printf("%-4s %-18s %s\n", "回", "x", "誤差");
    for (int step = 0; step <= 6; step++) {
        double err = fabs(x - answer);
        printf("%-4d %-18.15f %.3e\n", step, x, err);
        fprintf(csv, "%d,%.15f,%.15e\n", step, x, err);
        x = x - f(x) / df(x);
    }
    fclose(csv);

    printf("\n正解 %.15f\n", answer);
    printf("newton.csv に書き出しました。グラフで error を見てみましょう。\n");
    return 0;
}
