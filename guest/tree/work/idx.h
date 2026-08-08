/* IDX ファイルを読む
 *
 * MNIST の配布形式。中身は素直で、
 *
 *   4 バイト  マジック（0x0801 = ラベル, 0x0803 = 画像）
 *   4 バイト  次元ごとの大きさ（ビッグエンディアン）× 次元数
 *   あとは    unsigned char がぎっしり
 *
 * これだけなので、ライブラリは要りません。
 */
#ifndef IDX_H
#define IDX_H

#include <stdio.h>
#include <stdlib.h>

/* 読み込んだ中身。count 個のデータが、1個あたり stride バイト。 */
typedef struct {
    int count;
    int stride;
    unsigned char* data;
} Idx;

static unsigned read_be32(FILE* f) {          /* ビッグエンディアンの 4 バイト */
    unsigned v = 0;
    for (int i = 0; i < 4; i++) v = (v << 8) | (unsigned)fgetc(f);
    return v;
}

static Idx read_idx(const char* path) {
    Idx idx = {0, 1, NULL};
    FILE* f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "開けません: %s\n", path);
        exit(1);
    }
    unsigned magic = read_be32(f);            /* 0x0000_08NN、NN が次元数 */
    int dims = (int)(magic & 0xff);
    idx.count = (int)read_be32(f);
    for (int i = 1; i < dims; i++) idx.stride *= (int)read_be32(f);

    size_t total = (size_t)idx.count * (size_t)idx.stride;
    idx.data = malloc(total);
    if (!idx.data || fread(idx.data, 1, total, f) != total) {
        fprintf(stderr, "読めません: %s\n", path);
        exit(1);
    }
    fclose(f);
    return idx;
}

#endif
