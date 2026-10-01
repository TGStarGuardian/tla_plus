#pragma once

#include <algorithm>
#include <cstddef>
#include <span>

namespace bubble_sort {

inline void sort(std::span<int> a) {
    for (auto end = a.size(); end > 1; --end) {
        bool swapped = false;
        for (std::size_t i = 1; i < end; ++i) {
            if (a[i - 1] > a[i]) {
                std::swap(a[i - 1], a[i]);
                swapped = true;
            }
        }
        if (!swapped) break;
    }
}

}  // namespace bubble_sort
