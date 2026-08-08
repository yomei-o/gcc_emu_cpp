#include <cstdio>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <cmath>
#include <memory>
#include <sstream>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::map<std::string, int> m{{"a", 1}};
    auto p = std::make_unique<int>(7);
    std::ostringstream os;
    os << "C++ " << v.size() << " " << m["a"] << " " << *p << " " << std::sqrt(2.0);
    std::printf("%s\n", os.str().c_str());
    return 0;
}
