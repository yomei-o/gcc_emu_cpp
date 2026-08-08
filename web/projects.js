// The projects the site ships with.
//
// Each is a small, complete program that does one thing and prints something
// worth looking at.  Several write a CSV, because seeing an algorithm's shape
// is the point of the exercise and the page can draw one.
//
// They are here as text rather than as files to fetch: together they are a few
// tens of kilobytes, and a project that opens instantly is a project a student
// will actually open.  The one exception is MNIST, whose data is fetched.

export const PROJECTS = {
    'hello-c': {
        title: 'C: はじめの一歩',
        note: 'printf で挨拶するだけ。まずはここから。',
        files: {
            'main.c': `#include <stdio.h>

int main(void) {
    printf("こんにちは、C の世界\\n");

    /* 変数と計算 */
    int a = 6, b = 7;
    printf("%d かける %d は %d\\n", a, b, a * b);

    /* 繰り返し */
    for (int i = 1; i <= 5; i++) {
        printf("%d の2乗は %d\\n", i, i * i);
    }
    return 0;
}
`,
        },
    },

    'hello-cpp': {
        title: 'C++: はじめの一歩',
        note: 'std::vector と std::string を使ってみる。',
        files: {
            'main.cpp': `#include <iostream>
#include <string>
#include <vector>
#include <algorithm>

int main() {
    std::cout << "こんにちは、C++ の世界" << std::endl;

    std::vector<std::string> names{"さくら", "かえで", "あおい"};
    std::sort(names.begin(), names.end());

    for (const auto& n : names) {
        std::cout << n << " (" << n.size() << " バイト)" << std::endl;
    }

    // ラムダ式と algorithm
    std::vector<int> v{5, 3, 8, 1, 9, 2};
    auto big = std::count_if(v.begin(), v.end(), [](int x) { return x > 4; });
    std::cout << "4 より大きい数は " << big << " 個" << std::endl;
    return 0;
}
`,
        },
    },

    'newton-sin': {
        title: 'ニュートン法で sin を解く',
        note: 'sin(x) = 0.5 になる x を、微分と反復で追い込む。収束の速さを CSV に出す。',
        csv: 'newton.csv',
        files: {
            'main.c': `/* ニュートン法
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
    fprintf(csv, "step,x,error\\n");

    printf("%-4s %-18s %s\\n", "回", "x", "誤差");
    for (int step = 0; step <= 6; step++) {
        double err = fabs(x - answer);
        printf("%-4d %-18.15f %.3e\\n", step, x, err);
        fprintf(csv, "%d,%.15f,%.15e\\n", step, x, err);
        x = x - f(x) / df(x);
    }
    fclose(csv);

    printf("\\n正解 %.15f\\n", answer);
    printf("newton.csv に書き出しました。グラフで error を見てみましょう。\\n");
    return 0;
}
`,
        },
    },

    'z-transform': {
        title: 'Z 変換で sin を作る',
        note: '極を2つ置いた漸化式だけで、三角関数を呼ばずに正弦波が出る。',
        csv: 'wave.csv',
        files: {
            'main.c': `/* Z 変換と、正弦波を作る漸化式
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
    fprintf(csv, "n,recurrence,sin\\n");

    for (int n = 0; n < N; n++) {
        double x1 = (n == 1) ? 1.0 : 0.0;         /* 単位インパルス */
        double y = a1 * y1 - y2 + b1 * x1;
        y2 = y1;
        y1 = y;

        /* 答え合わせ用に本物の sin も出す */
        fprintf(csv, "%d,%.9f,%.9f\\n", n, y, sin(w * n));
    }
    fclose(csv);

    printf("wave.csv を書きました。\\n");
    printf("recurrence と sin を重ねると、ぴったり同じ波になります。\\n");
    return 0;
}
`,
        },
    },

    'bubble-sort': {
        title: 'バブルソート、収束のかたち',
        note: '1回ごとの「乱れ具合」を測ると、まっすぐ落ちていくのが見える。',
        csv: 'bubble.csv',
        files: {
            'main.c': `/* バブルソートが「どう」整っていくか
 *
 * 速さを比べるのではなく、途中経過を測る。
 *
 *   inversions  まだ順序が逆になっている組の数。これが 0 で完成。
 *   displacement 各要素が、最終的な位置からどれだけ離れているかの合計。
 *
 * バブルソートは隣どうししか交換しないので、1回のパスで
 * inversions はせいぜい n しか減らない。だからグラフは
 * ほぼ直線に落ちていく。クイックソートと見比べてください。
 */
#include <stdio.h>
#include <stdlib.h>

#define N 120

static long inversions(const int* a, int n) {
    long c = 0;
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++)
            if (a[i] > a[j]) c++;
    return c;
}

static long displacement(const int* a, int n) {
    long d = 0;
    for (int i = 0; i < n; i++) {
        /* 値そのものが最終位置（0..N-1 を並べ替えただけなので） */
        d += labs((long)a[i] - i);
    }
    return d;
}

int main(void) {
    int a[N];
    for (int i = 0; i < N; i++) a[i] = i;

    /* 決まった順でかき混ぜる（毎回同じ結果になるように） */
    unsigned seed = 12345;
    for (int i = N - 1; i > 0; i--) {
        seed = seed * 1103515245u + 12345u;
        int j = (seed >> 16) % (i + 1);
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }

    FILE* csv = fopen("bubble.csv", "w");
    fprintf(csv, "pass,inversions,displacement\\n");
    fprintf(csv, "0,%ld,%ld\\n", inversions(a, N), displacement(a, N));

    long swaps = 0;
    for (int pass = 1; pass <= N; pass++) {
        int moved = 0;
        for (int i = 0; i + 1 < N; i++) {
            if (a[i] > a[i + 1]) {
                int t = a[i]; a[i] = a[i + 1]; a[i + 1] = t;
                moved = 1;
                swaps++;
            }
        }
        fprintf(csv, "%d,%ld,%ld\\n", pass, inversions(a, N), displacement(a, N));
        if (!moved) {
            printf("%d 回目のパスで、もう動かすものがなくなりました\\n", pass);
            break;
        }
    }
    fclose(csv);

    printf("交換した回数: %ld\\n", swaps);
    printf("bubble.csv を書きました。pass に対して inversions を描くと、\\n");
    printf("まっすぐ落ちていくのが見えます。\\n");
    return 0;
}
`,
        },
    },

    'quick-sort': {
        title: 'クイックソート、収束のかたち',
        note: '同じ乱れ具合を測ると、こちらは階段状に一気に落ちる。',
        csv: 'quick.csv',
        files: {
            'main.c': `/* クイックソートが「どう」整っていくか
 *
 * bubble-sort と同じ数列、同じ測り方。違うのは手順だけ。
 *
 * クイックソートは遠く離れた要素どうしを交換するので、
 * 1回の分割で inversions が大きく減る。バブルソートの
 * 直線に対して、こちらは段差になって落ちていきます。
 *
 * 横軸は「比較した回数」。手順が違うものを同じ物差しで
 * 見るために、パス数ではなく仕事量で測っています。
 */
#include <stdio.h>
#include <stdlib.h>

#define N 120

static int a[N];
static long comparisons = 0;
static FILE* csv;

static long inversions(void) {
    long c = 0;
    for (int i = 0; i < N; i++)
        for (int j = i + 1; j < N; j++)
            if (a[i] > a[j]) c++;
    return c;
}

static long displacement(void) {
    long d = 0;
    for (int i = 0; i < N; i++) d += labs((long)a[i] - i);
    return d;
}

static void note(void) {
    fprintf(csv, "%ld,%ld,%ld\\n", comparisons, inversions(), displacement());
}

static void quicksort(int lo, int hi) {
    if (lo >= hi) return;

    int pivot = a[(lo + hi) / 2];
    int i = lo, j = hi;
    while (i <= j) {
        while (a[i] < pivot) { i++; comparisons++; }
        while (a[j] > pivot) { j--; comparisons++; }
        if (i <= j) {
            int t = a[i]; a[i] = a[j]; a[j] = t;
            i++; j--;
        }
    }
    note();                 /* 分割し終えるたびに測る */
    quicksort(lo, j);
    quicksort(i, hi);
}

int main(void) {
    for (int i = 0; i < N; i++) a[i] = i;

    unsigned seed = 12345;  /* bubble-sort と同じ種、同じ並び */
    for (int i = N - 1; i > 0; i--) {
        seed = seed * 1103515245u + 12345u;
        int j = (seed >> 16) % (i + 1);
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }

    csv = fopen("quick.csv", "w");
    fprintf(csv, "comparisons,inversions,displacement\\n");
    note();
    quicksort(0, N - 1);
    fclose(csv);

    printf("比較した回数: %ld\\n", comparisons);
    printf("quick.csv を書きました。comparisons に対して inversions を描き、\\n");
    printf("bubble.csv と見比べてみてください。\\n");
    return 0;
}
`,
        },
    },
};
