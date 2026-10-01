#include "quicksort.hpp"

#include <cassert>
#include <climits>
#include <iostream>
#include <vector>

void check_sort(const std::vector<int>& input) {
    auto expected = input;
    std::sort(expected.begin(), expected.end());
    for (unsigned seed : {0u, 1u, 42u}) {
        auto actual = input;
        std::mt19937 random(seed);
        quicksort::sort(actual, random);
        assert(actual == expected);
    }
}

void check_partitions(const std::vector<int>& input) {
    for (std::size_t lo = 0; lo < input.size(); ++lo) {
        for (std::size_t hi = lo + 1; hi <= input.size(); ++hi) {
            for (std::size_t p = lo; p < hi; ++p) {
                auto a = input;
                const auto [lt, gt] = quicksort::detail::partition(a, lo, hi, p);
                assert(lo <= lt && lt < gt && gt <= hi);
                for (std::size_t k = 0; k < a.size(); ++k) {
                    if (k < lo || k >= hi) assert(a[k] == input[k]);
                    else if (k < lt) assert(a[k] < input[p]);
                    else if (k < gt) assert(a[k] == input[p]);
                    else assert(a[k] > input[p]);
                }
                auto expected = input;
                std::sort(expected.begin() + lo, expected.begin() + hi);
                // The equal block already agrees with the fully sorted subrange.
                for (auto k = lt; k < gt; ++k) assert(a[k] == expected[k]);
                std::sort(a.begin() + lo, a.begin() + hi);
                assert(a == expected);
            }
        }
    }
}

int main() {
    std::size_t count = 0, combinations = 1;
    for (std::size_t n = 0; n <= 8; ++n, combinations *= 3) {
        for (std::size_t code = 0; code < combinations; ++code) {
            std::vector<int> a(n);
            auto digits = code;
            for (auto& value : a) {
                value = static_cast<int>(digits % 3) - 1;
                digits /= 3;
            }
            check_sort(a);
            if (n <= 6) check_partitions(a);
            ++count;
        }
    }
    check_sort({INT_MAX, 0, INT_MIN, INT_MAX, INT_MIN, -1, 1});
    check_partitions({INT_MAX, 0, INT_MIN, INT_MAX, INT_MIN, -1, 1});
    std::vector<int> large(100000, 7);
    check_sort(large);
    for (std::size_t i = 0; i < large.size(); ++i) large[i] = static_cast<int>(i);
    check_sort(large);
    std::reverse(large.begin(), large.end());
    check_sort(large);
    std::mt19937 random(123);
    for (auto& value : large) value = std::uniform_int_distribution<int>(INT_MIN, INT_MAX)(random);
    check_sort(large);
    std::cout << "Passed " << count << " exhaustive sorting inputs, all subrange/pivot checks"
              << " through length 6, and integer-limit/large-input checks.\n";
}
