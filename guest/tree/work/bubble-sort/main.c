/* バブルソートが「どう」整っていくか
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
    fprintf(csv, "pass,inversions,displacement\n");
    fprintf(csv, "0,%ld,%ld\n", inversions(a, N), displacement(a, N));

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
        fprintf(csv, "%d,%ld,%ld\n", pass, inversions(a, N), displacement(a, N));
        if (!moved) {
            printf("%d 回目のパスで、もう動かすものがなくなりました\n", pass);
            break;
        }
    }
    fclose(csv);

    printf("交換した回数: %ld\n", swaps);
    printf("bubble.csv を書きました。pass に対して inversions を描くと、\n");
    printf("まっすぐ落ちていくのが見えます。\n");
    return 0;
}
