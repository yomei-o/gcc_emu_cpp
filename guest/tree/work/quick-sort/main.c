/* クイックソートが「どう」整っていくか
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
    fprintf(csv, "%ld,%ld,%ld\n", comparisons, inversions(), displacement());
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
    fprintf(csv, "comparisons,inversions,displacement\n");
    note();
    quicksort(0, N - 1);
    fclose(csv);

    printf("比較した回数: %ld\n", comparisons);
    printf("quick.csv を書きました。comparisons に対して inversions を描き、\n");
    printf("bubble.csv と見比べてみてください。\n");
    return 0;
}
