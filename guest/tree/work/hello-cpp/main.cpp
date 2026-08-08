#include <iostream>
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
