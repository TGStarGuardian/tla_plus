#pragma once

#include <algorithm>
#include <cstddef>
#include <span>
#include <vector>

namespace merge_sort {

inline void sort(std::span<int> a) {
    const auto n = a.size();
    if (n < 2) return;
    std::vector<int> buffer(n);
    for (std::size_t width = 1; width < n;) {
        for (std::size_t lo = 0; lo < n;) {
            // Bound additions by the remaining length to avoid size overflow.
            const auto mid = lo + std::min(width, n - lo);
            const auto hi = mid + std::min(width, n - mid);
            auto left = lo, right = mid;
            for (auto out = lo; out < hi; ++out) {
                if (left < mid && (right == hi || a[left] <= a[right])) {
                    buffer[out] = a[left++];
                } else {
                    buffer[out] = a[right++];
                }
            }
            for (auto k = lo; k < hi; ++k) a[k] = buffer[k];
            lo = hi;
        }
        if (width >= n - width) break;
        width *= 2;
    }
}

}  // namespace merge_sort
