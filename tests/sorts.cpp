#include "../insertion_sort/insertion_sort.hpp"
#include "../selection_sort/selection_sort.hpp"
#include "../merge_sort/merge_sort.hpp"
#include "../bubble_sort/bubble_sort.hpp"
#include "../heap_sort/heap_sort.hpp"

#include <cassert>
#include <climits>
#include <iostream>
#include <random>

using Sort = void (*)(std::span<int>);

void check(Sort sort, const std::vector<int>& input) {
    auto expected = input;
    std::sort(expected.begin(), expected.end());
    auto actual = input;
    sort(actual);
    assert(actual == expected);

    // A subspan must preserve adjacent caller-owned storage, including if empty.
    actual = input;
    actual.insert(actual.begin(), INT_MAX);
    actual.push_back(INT_MIN);
    sort(std::span<int>(actual).subspan(1, input.size()));
    assert(actual.front() == INT_MAX && actual.back() == INT_MIN);
    assert(std::equal(expected.begin(), expected.end(), actual.begin() + 1));
}

int main() {
    std::size_t count = 0, combinations = 1;
    const Sort sorters[] = {insertion_sort::sort, selection_sort::sort, merge_sort::sort,
                            bubble_sort::sort, heap_sort::sort};
    for (std::size_t n = 0; n <= 8; ++n, combinations *= 3) {
        for (std::size_t code = 0; code < combinations; ++code) {
            std::vector<int> a(n);
            auto digits = code;
            for (auto& value : a) {
                value = static_cast<int>(digits % 3) - 1;
                digits /= 3;
            }
            for (auto sort : sorters) check(sort, a);
            ++count;
        }
    }
    std::mt19937 random(42);
    for (auto sort : sorters) {
        check(sort, {INT_MIN, INT_MAX, 0, INT_MIN, 1, INT_MAX, -1});
        for (std::size_t n : {31u, 32u, 33u, 255u, 256u, 257u, 2048u}) {
            std::vector<int> a(n, 7);
            check(sort, a);
            for (std::size_t k = 0; k < n; ++k) a[k] = static_cast<int>(k);
            check(sort, a);
            std::reverse(a.begin(), a.end());
            check(sort, a);
            for (auto& value : a) value = std::uniform_int_distribution<int>(INT_MIN, INT_MAX)(random);
            check(sort, a);
        }
    }
    for (std::size_t n : {65535u, 65536u, 65537u, 100000u}) {
        std::vector<int> a(n);
        for (auto& value : a) value = std::uniform_int_distribution<int>(-100, 100)(random);
        check(merge_sort::sort, a);
        check(heap_sort::sort, a);
    }
    std::cout << "Passed " << count << " exhaustive inputs per deterministic sorter, including subspans,"
              << " integer limits, and larger structured/random inputs.\n";
}
