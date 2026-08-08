/* MNIST: 手書き数字を学習して当てる。C だけで。
 *
 *   入力 784 (28x28) → 隠れ層 HIDDEN (ReLU) → 出力 10 (softmax)
 *
 * 行列ライブラリは使いません。掛け算を素直に三重ループで書いた方が、
 * 何が起きているか読めるので。
 *
 * エミュレータの上では掛け算 1 回が実機の百倍くらいかかります。
 * この設定でおよそ 1 分:
 *
 *   TRAIN 600,   EPOCHS 2  →  約 1 分   （既定）
 *   TRAIN 4000,  EPOCHS 3  →  10〜30 分
 *   TRAIN 60000, EPOCHS 5  →  一晩
 *
 * 数を変えて、正解率がどう変わるか見てみてください。
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "idx.h"

#define PIXELS 784
#define HIDDEN 16
#define OUT    10

#define TRAIN  600      /* 60000 まで増やせます */
#define TEST   200      /* 10000 まで */
#define EPOCHS 2
#define LR     0.1f

/* 重みとバイアス。静的に置くので、確保も解放も要りません。 */
static float w1[HIDDEN][PIXELS], b1[HIDDEN];
static float w2[OUT][HIDDEN],    b2[OUT];

/* 途中の値。毎回確保しないよう、ここに置いておきます。 */
static float h[HIDDEN], p[OUT], dh[HIDDEN];

/* 乱数。毎回同じ結果になるよう、自前の線形合同法で。 */
static unsigned seed = 42;
static float rnd(void) {
    seed = seed * 1103515245u + 12345u;
    return (float)((seed >> 16) & 0x7fff) / 32767.0f - 0.5f;
}

static void init(void) {
    /* He の初期化: ReLU のときは入力数の平方根で割ると具合がよい */
    float s1 = sqrtf(2.0f / PIXELS), s2 = sqrtf(2.0f / HIDDEN);
    for (int j = 0; j < HIDDEN; j++)
        for (int i = 0; i < PIXELS; i++) w1[j][i] = rnd() * 2.0f * s1;
    for (int k = 0; k < OUT; k++)
        for (int j = 0; j < HIDDEN; j++) w2[k][j] = rnd() * 2.0f * s2;
}

/* 前向き計算。x は 0..1 に正規化済みの 784 個。 */
static void forward(const float* x) {
    for (int j = 0; j < HIDDEN; j++) {
        float s = b1[j];
        for (int i = 0; i < PIXELS; i++) s += w1[j][i] * x[i];
        h[j] = s > 0.0f ? s : 0.0f;                    /* ReLU */
    }
    float max = -1e30f;
    for (int k = 0; k < OUT; k++) {
        float s = b2[k];
        for (int j = 0; j < HIDDEN; j++) s += w2[k][j] * h[j];
        p[k] = s;
        if (s > max) max = s;
    }
    /* softmax。最大値を引くのは exp が溢れないようにするため */
    float sum = 0.0f;
    for (int k = 0; k < OUT; k++) { p[k] = expf(p[k] - max); sum += p[k]; }
    for (int k = 0; k < OUT; k++) p[k] /= sum;
}

/* 後ろ向き計算と更新。
 *
 * 交差エントロピー + softmax なので、出力層の勾配は (p - 正解) という
 * きれいな形になります。導出は教科書に譲りますが、この一行が
 * 「間違えた分だけ動かす」という意味だと分かれば十分です。
 */
static void train_one(const float* x, int label) {
    forward(x);

    for (int j = 0; j < HIDDEN; j++) dh[j] = 0.0f;
    for (int k = 0; k < OUT; k++) {
        float g = p[k] - (k == label ? 1.0f : 0.0f);
        for (int j = 0; j < HIDDEN; j++) {
            dh[j] += g * w2[k][j];
            w2[k][j] -= LR * g * h[j];
        }
        b2[k] -= LR * g;
    }
    for (int j = 0; j < HIDDEN; j++) {
        if (h[j] <= 0.0f) continue;                    /* ReLU の外は伝わらない */
        float g = dh[j];
        for (int i = 0; i < PIXELS; i++) w1[j][i] -= LR * g * x[i];
        b1[j] -= LR * g;
    }
}

static int guess(const float* x) {
    forward(x);
    int best = 0;
    for (int k = 1; k < OUT; k++) if (p[k] > p[best]) best = k;
    return best;
}

int main(void) {
    printf("読み込んでいます...\n");
    Idx train_x = read_idx("train-images.idx");
    Idx train_y = read_idx("train-labels.idx");
    Idx test_x  = read_idx("test-images.idx");
    Idx test_y  = read_idx("test-labels.idx");
    printf("学習 %d 件 / 検証 %d 件 / 1 件 %d 画素\n", TRAIN, TEST, train_x.stride);

    /* 0..255 を 0..1 に。ここで一度だけ変換しておきます。 */
    static float X[TRAIN][PIXELS], TX[TEST][PIXELS];
    for (int i = 0; i < TRAIN; i++)
        for (int j = 0; j < PIXELS; j++)
            X[i][j] = train_x.data[(size_t)i * PIXELS + j] / 255.0f;
    for (int i = 0; i < TEST; i++)
        for (int j = 0; j < PIXELS; j++)
            TX[i][j] = test_x.data[(size_t)i * PIXELS + j] / 255.0f;

    init();

    FILE* csv = fopen("training.csv", "w");
    fprintf(csv, "step,loss,accuracy\n");

    printf("\n%-6s %-10s %s\n", "回", "損失", "正解率");
    int step = 0;
    double loss = 0.0;
    for (int epoch = 0; epoch < EPOCHS; epoch++) {
        for (int i = 0; i < TRAIN; i++) {
            forward(X[i]);
            loss += -log(p[train_y.data[i]] + 1e-9);
            train_one(X[i], train_y.data[i]);

            /* ときどき測って書く。測るのも計算なので、頻繁にはやりません。 */
            if (++step % 100 == 0) {
                int right = 0;
                for (int t = 0; t < TEST; t++)
                    if (guess(TX[t]) == test_y.data[t]) right++;
                float acc = right * 100.0f / TEST;
                fprintf(csv, "%d,%.5f,%.2f\n", step, loss / 100.0, acc);
                printf("%-6d %-10.4f %.1f%%\n", step, loss / 100.0, acc);
                loss = 0.0;
            }
        }
    }
    fclose(csv);

    int right = 0;
    for (int t = 0; t < TEST; t++) if (guess(TX[t]) == test_y.data[t]) right++;
    printf("\n最終の正解率: %.1f%%\n", right * 100.0f / TEST);
    printf("training.csv を書きました。step に対して accuracy を描いてみてください。\n");

    /* 1 枚だけ、絵として出してみる */
    printf("\nテストの 1 枚目 (正解 %d):\n", (int)test_y.data[0]);
    for (int r = 0; r < 28; r++) {
        for (int c = 0; c < 28; c++) {
            unsigned char v = test_x.data[(size_t)r * 28 + c];
            printf("%s", v > 170 ? "##" : v > 85 ? "++" : v > 30 ? ".." : "  ");
        }
        printf("\n");
    }
    int best = guess(TX[0]);
    printf("これは %d だと思います (確信度 %.0f%%)\n", best, p[best] * 100);
    return 0;
}
