// Precompiled and shipped: see tools/wslmkpch.sh.
//
// The page passes -include std.hpp to every C++ build, so a program gets these
// whether it asks or not.  Its own #include <vector> then costs nothing - the
// include guard is already defined.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <numeric>
#include <set>
#include <sstream>
#include <string>
#include <vector>
