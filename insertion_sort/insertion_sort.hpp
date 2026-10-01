#pragma once

#include <cstddef>
#include <span>

namespace insertion_sort {

inline void sort(std::span<int> a) {
    for (std::size_t i = 1; i < a.size(); ++i) {
        const int key = a[i];
        auto j = i;
        while (j > 0 && a[j - 1] > key) {
            a[j] = a[j - 1];
            --j;
        }
        a[j] = key;
    }
}

}  // namespace insertion_sort
