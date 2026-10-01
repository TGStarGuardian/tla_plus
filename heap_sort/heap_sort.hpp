#pragma once

#include <algorithm>
#include <cstddef>
#include <span>

namespace heap_sort {
namespace detail {

// Child subtrees must already be heaps; end is the exclusive heap bound.
inline void sift_down(std::span<int> a, std::size_t root, std::size_t end) {
    const int saved = a[root];
    auto hole = root;
    // Test for a child before computing its index, avoiding size overflow.
    while (hole < end / 2) {
        auto child = 2 * hole + 1;
        if (child + 1 < end && a[child] < a[child + 1]) ++child;
        if (saved >= a[child]) break;
        a[hole] = a[child];
        hole = child;
    }
    a[hole] = saved;
}

}  // namespace detail

inline void sort(std::span<int> a) {
    const auto n = a.size();
    if (n < 2) return;
    for (auto root = n / 2; root > 0;) detail::sift_down(a, --root, n);
    for (auto end = n; end > 1;) {
        std::swap(a[0], a[end - 1]);
        detail::sift_down(a, 0, --end);
    }
}

}  // namespace heap_sort
