#pragma once

#include <algorithm>
#include <cstddef>
#include <span>

namespace selection_sort {

inline void sort(std::span<int> a) {
    if (a.empty()) return;
    for (std::size_t i = 0; i < a.size() - 1; ++i) {
        auto minimum = i;
        for (auto j = i + 1; j < a.size(); ++j) {
            if (a[j] < a[minimum]) minimum = j;
        }
        if (minimum != i) std::swap(a[i], a[minimum]);
    }
}

}  // namespace selection_sort
