#pragma once

#include <algorithm>
#include <cstddef>
#include <random>
#include <span>
#include <utility>

namespace quicksort {
namespace detail {

// [lo, hi), with lo <= pivot_index < hi. Returns the equal block [lt, gt).
inline std::pair<std::size_t, std::size_t> partition(
    std::span<int> a, std::size_t lo, std::size_t hi,
    std::size_t pivot_index) {
    const int pivot = a[pivot_index];
    std::size_t lt = lo, scan = lo, gt = hi;
    while (scan < gt) {
        if (a[scan] < pivot) {
            std::swap(a[lt++], a[scan++]);
        } else if (a[scan] > pivot) {
            std::swap(a[scan], a[--gt]);
        } else {
            ++scan;
        }
    }
    return {lt, gt};
}

inline void sort_range(std::span<int> a, std::size_t lo, std::size_t hi,
                       std::mt19937& random) {
    while (hi - lo > 1) {
        const auto pivot = std::uniform_int_distribution<std::size_t>(lo, hi - 1)(random);
        const auto [lt, gt] = partition(a, lo, hi, pivot);
        // Recursing only into the smaller side bounds stack depth for any pivots.
        if (lt - lo < hi - gt) {
            sort_range(a, lo, lt, random);
            lo = gt;
        } else {
            sort_range(a, gt, hi, random);
            hi = lt;
        }
    }
}

}  // namespace detail

// The caller owns/seeds the generator; sorting allocates no array storage.
inline void sort(std::span<int> a, std::mt19937& random) {
    detail::sort_range(a, 0, a.size(), random);
}

}  // namespace quicksort
