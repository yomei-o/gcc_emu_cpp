// MNIST, in C++ and nothing else.
//
// How big it is was decided by arithmetic rather than by taste, after the first
// attempt - 4000 images, three epochs - was still running an hour later.  The
// count is knowable in advance: a forward pass is 784x16 + 16x10 multiply-adds,
// training is three of those per image, and evaluating the test set is as
// expensive as the training it interrupts.  That came to 1.5 billion operations,
// or twenty to forty minutes.
//
// So: 600 images, two epochs, a test set of 200, measured every hundred steps.
// About a minute, and about 80%.  Every one of those is a constant at the top of
// main.cpp with the cost of raising it written beside it - which is a better
// lesson than a number that was chosen for them.
//
// The data is a header-only decoder over the original IDX files, gzipped - no
// library, no tar, and the format is simple enough to read in the source.

export const MNIST = {
    title: 'MNIST を C++ だけで',
    note: '手書き数字を、ライブラリなしで学習して当てる。1分ほどで 80% くらいまで来ます。数を増やせばもっと上がります。',
    csv: 'training.csv',
    // Fetched rather than carried in the page: 11 MB of it.
    data: [
        ['train-images.idx', 'data/train-images-idx3-ubyte.gz'],
        ['train-labels.idx', 'data/train-labels-idx1-ubyte.gz'],
        ['test-images.idx', 'data/t10k-images-idx3-ubyte.gz'],
        ['test-labels.idx', 'data/t10k-labels-idx1-ubyte.gz'],
    ],
    files: {
        'idx.hpp': `// IDX ファイルを読むだけのヘッダ
//
// MNIST の配布形式。中身は素直で、
//
//   4 バイト  マジック（0x0801 = 1次元/ラベル, 0x0803 = 3次元/画像）
//   4 バイト  次元ごとの大きさ（ビッグエンディアン）× 次元数
//   あとは    unsigned char がぎっしり
//
// これだけなので、ライブラリは要りません。
#pragma once
#include <cstdint>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

struct Idx {
    std::vector<int> shape;
    std::vector<unsigned char> data;

    int count() const { return shape.empty() ? 0 : shape[0]; }
    // 1 件あたりの大きさ（画像なら 28*28 = 784、ラベルなら 1）
    int stride() const {
        int n = 1;
        for (size_t i = 1; i < shape.size(); i++) n *= shape[i];
        return n;
    }
};

inline Idx read_idx(const std::string& path) {
    std::FILE* f = std::fopen(path.c_str(), "rb");
    if (!f) throw std::runtime_error("開けません: " + path);

    auto u8 = [&] {
        int c = std::fgetc(f);
        if (c == EOF) throw std::runtime_error("途中で終わっています: " + path);
        return (unsigned char)c;
    };
    auto u32 = [&] {                       // ビッグエンディアン
        uint32_t v = 0;
        for (int i = 0; i < 4; i++) v = (v << 8) | u8();
        return v;
    };

    if (u8() != 0 || u8() != 0) throw std::runtime_error("IDX ではありません: " + path);
    unsigned char type = u8();
    if (type != 0x08) throw std::runtime_error("unsigned char 以外は読めません");
    int dims = u8();

    Idx idx;
    size_t total = 1;
    for (int i = 0; i < dims; i++) {
        int n = (int)u32();
        idx.shape.push_back(n);
        total *= (size_t)n;
    }
    idx.data.resize(total);
    if (std::fread(idx.data.data(), 1, total, f) != total)
        throw std::runtime_error("短すぎます: " + path);
    std::fclose(f);
    return idx;
}
`,
        'net.hpp': `// 2 層のニューラルネット
//
//   入力 784 → 隠れ層 H (ReLU) → 出力 10 (softmax)
//
// 行列ライブラリは使いません。掛け算を素直に書いた方が、
// 何が起きているか読めるので。
#pragma once
#include <cmath>
#include <cstddef>
#include <vector>

struct Net {
    int in, hidden, out;
    std::vector<float> w1, b1, w2, b2;

    // 乱数。毎回同じ結果になるように、自前の線形合同法で。
    unsigned seed = 42;
    float rnd() {
        seed = seed * 1103515245u + 12345u;
        return ((seed >> 16) & 0x7fff) / 32767.0f - 0.5f;
    }

    Net(int in_, int hidden_, int out_) : in(in_), hidden(hidden_), out(out_) {
        w1.resize((size_t)in * hidden);
        b1.assign(hidden, 0.0f);
        w2.resize((size_t)hidden * out);
        b2.assign(out, 0.0f);
        // He の初期化: ReLU のときは入力数の平方根で割ると具合がよい
        float s1 = std::sqrt(2.0f / in), s2 = std::sqrt(2.0f / hidden);
        for (auto& v : w1) v = rnd() * 2.0f * s1;
        for (auto& v : w2) v = rnd() * 2.0f * s2;
    }

    // 前向き計算。h と p は呼び出し側が用意する（毎回確保しないため）
    void forward(const float* x, std::vector<float>& h, std::vector<float>& p) const {
        for (int j = 0; j < hidden; j++) {
            float s = b1[j];
            const float* w = &w1[(size_t)j * in];
            for (int i = 0; i < in; i++) s += w[i] * x[i];
            h[j] = s > 0.0f ? s : 0.0f;              // ReLU
        }
        float max = -1e30f;
        for (int k = 0; k < out; k++) {
            float s = b2[k];
            const float* w = &w2[(size_t)k * hidden];
            for (int j = 0; j < hidden; j++) s += w[j] * h[j];
            p[k] = s;
            if (s > max) max = s;
        }
        // softmax。最大値を引くのは、exp が溢れないようにするため
        float sum = 0.0f;
        for (int k = 0; k < out; k++) { p[k] = std::exp(p[k] - max); sum += p[k]; }
        for (int k = 0; k < out; k++) p[k] /= sum;
    }

    // 後ろ向き計算と更新。交差エントロピー + softmax なので、
    // 出力層の勾配は (p - 正解) というきれいな形になる。
    void train_one(const float* x, int label, float lr,
                   std::vector<float>& h, std::vector<float>& p,
                   std::vector<float>& dh) {
        forward(x, h, p);

        for (int j = 0; j < hidden; j++) dh[j] = 0.0f;
        for (int k = 0; k < out; k++) {
            float g = p[k] - (k == label ? 1.0f : 0.0f);
            float* w = &w2[(size_t)k * hidden];
            for (int j = 0; j < hidden; j++) {
                dh[j] += g * w[j];
                w[j] -= lr * g * h[j];
            }
            b2[k] -= lr * g;
        }
        for (int j = 0; j < hidden; j++) {
            if (h[j] <= 0.0f) continue;              // ReLU の外
            float g = dh[j];
            float* w = &w1[(size_t)j * in];
            for (int i = 0; i < in; i++) w[i] -= lr * g * x[i];
            b1[j] -= lr * g;
        }
    }
};
`,
        'main.cpp': `// MNIST: 学習して、当てて、途中経過を CSV に出す
//
// エミュレータの上で動かすので、まずは小さく。TRAIN と EPOCHS を
// 増やせばそのまま本気の学習になります（そのぶん待ちます）。
#include <cstdio>
#include <vector>
#include <string>
#include "idx.hpp"
#include "net.hpp"

/* エミュレータの上では、掛け算1回が実機の百倍くらいかかります。
 * この設定でおよそ1分。増やせばそのぶん良くなりますが、そのぶん待ちます:
 *
 *   TRAIN 600, EPOCHS 2   →  約 1 分   （既定）
 *   TRAIN 4000, EPOCHS 3  →  10〜30 分
 *   TRAIN 60000, EPOCHS 5 →  一晩
 *
 * 数を変えて、正解率がどう変わるか見てみてください。 */
static const int TRAIN  = 600;    /* 60000 まで増やせます */
static const int TEST   = 200;    /* 10000 まで */
static const int HIDDEN = 16;
static const int EPOCHS = 2;
static const float LR   = 0.1f;   /* 少ないデータなので、少し大きめに */

int main() {
    std::printf("読み込んでいます...\\n");
    Idx train_x = read_idx("train-images.idx");
    Idx train_y = read_idx("train-labels.idx");
    Idx test_x  = read_idx("test-images.idx");
    Idx test_y  = read_idx("test-labels.idx");

    const int pixels = train_x.stride();
    std::printf("学習 %d 件 / 検証 %d 件 / 1 件 %d 画素\\n", TRAIN, TEST, pixels);

    // 0..255 を 0..1 に。ここで一度だけ変換しておく
    auto to_float = [&](const Idx& src, int n) {
        std::vector<float> v((size_t)n * pixels);
        for (size_t i = 0; i < v.size(); i++) v[i] = src.data[i] / 255.0f;
        return v;
    };
    std::vector<float> X  = to_float(train_x, TRAIN);
    std::vector<float> TX = to_float(test_x, TEST);

    Net net(pixels, HIDDEN, 10);
    std::vector<float> h(HIDDEN), p(10), dh(HIDDEN);

    std::FILE* csv = std::fopen("training.csv", "w");
    std::fprintf(csv, "step,loss,accuracy\\n");

    auto evaluate = [&] {
        int right = 0;
        for (int i = 0; i < TEST; i++) {
            net.forward(&TX[(size_t)i * pixels], h, p);
            int best = 0;
            for (int k = 1; k < 10; k++) if (p[k] > p[best]) best = k;
            if (best == test_y.data[i]) right++;
        }
        return right * 100.0f / TEST;
    };

    std::printf("\\n%-6s %-10s %s\\n", "回", "損失", "正解率");
    int step = 0;
    for (int epoch = 0; epoch < EPOCHS; epoch++) {
        double loss = 0.0;
        for (int i = 0; i < TRAIN; i++) {
            const float* x = &X[(size_t)i * pixels];
            int label = train_y.data[i];
            net.forward(x, h, p);
            loss += -std::log(p[label] + 1e-9f);
            net.train_one(x, label, LR, h, p, dh);

            // ときどき測って書く。測るのも計算なので、頻繁にはやらない
            if (++step % 100 == 0) {
                float acc = evaluate();
                std::fprintf(csv, "%d,%.5f,%.2f\\n", step, loss / 500.0, acc);
                std::printf("%-6d %-10.4f %.1f%%\\n", step, loss / 500.0, acc);
                loss = 0.0;
            }
        }
    }
    std::fclose(csv);

    std::printf("\\n最終の正解率: %.1f%%\\n", evaluate());
    std::printf("training.csv を書きました。step に対して accuracy を描いてみてください。\\n");

    // 1 枚だけ、絵として出してみる
    std::printf("\\nテストの 1 枚目 (正解 %d):\\n", (int)test_y.data[0]);
    for (int r = 0; r < 28; r++) {
        for (int c = 0; c < 28; c++) {
            unsigned char v = test_x.data[(size_t)r * 28 + c];
            std::printf("%s", v > 170 ? "##" : v > 85 ? "++" : v > 30 ? ".." : "  ");
        }
        std::printf("\\n");
    }
    net.forward(&TX[0], h, p);
    int best = 0;
    for (int k = 1; k < 10; k++) if (p[k] > p[best]) best = k;
    std::printf("これは %d だと思います (確信度 %.0f%%)\\n", best, p[best] * 100);
    return 0;
}
`,
    },
};
