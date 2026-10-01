SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
CXX ?= g++
BUILD_DIR ?= /tmp/tla-plus-checks
TLA_TOOLS_JAR ?=
TEST_FLAGS := -std=c++20 -O1 -g -Wall -Wextra -Wpedantic -Wconversion -fsanitize=address,undefined -fno-omit-frame-pointer
JAVA_FLAGS := -XX:+UseParallelGC -Xmx2g -DTLA-Library=$(CURDIR)/common

.PHONY: check test models quicksort-model insertion-model selection-model merge-model bubble-model heap-model selection-witness heap-witness

check: test models selection-witness heap-witness

test:
	mkdir -p "$(BUILD_DIR)"
	$(CXX) $(TEST_FLAGS) quicksort/test.cpp -o "$(BUILD_DIR)/quicksort-test"
	"$(BUILD_DIR)/quicksort-test"
	$(CXX) $(TEST_FLAGS) tests/sorts.cpp -o "$(BUILD_DIR)/sorts-test"
	"$(BUILD_DIR)/sorts-test"

models: quicksort-model insertion-model selection-model merge-model bubble-model heap-model

define model
$(1):
	test -f "$(TLA_TOOLS_JAR)" || { echo 'Set TLA_TOOLS_JAR to an absolute tools JAR path.'; exit 1; }
	mkdir -p "$(BUILD_DIR)"
	cd $(2) && java $(JAVA_FLAGS) -cp "$(TLA_TOOLS_JAR)" tlc2.TLC -workers 2 \
	    -metadir "$(BUILD_DIR)/$(3)-states" -config $(3).cfg $(3).tla \
	    | tee "$(BUILD_DIR)/$(3).log"
endef

$(eval $(call model,quicksort-model,quicksort,Quicksort))
$(eval $(call model,insertion-model,insertion_sort,InsertionSort))
$(eval $(call model,selection-model,selection_sort,SelectionSort))
$(eval $(call model,merge-model,merge_sort,MergeSort))
$(eval $(call model,bubble-model,bubble_sort,BubbleSort))
$(eval $(call model,heap-model,heap_sort,HeapSort))

# Success here means TLC found precisely the intended stability counterexample.
selection-witness:
	test -f "$(TLA_TOOLS_JAR)"
	mkdir -p "$(BUILD_DIR)"
	cd selection_sort; set +e; \
	java $(JAVA_FLAGS) -cp "$(TLA_TOOLS_JAR)" tlc2.TLC -workers 1 -noGenerateSpecTE \
	    -metadir "$(BUILD_DIR)/witness-states" -config Unstable.cfg SelectionSort.tla \
	    > "$(BUILD_DIR)/selection-witness.log" 2>&1; result=$$?; set -e; \
	cat "$(BUILD_DIR)/selection-witness.log"; \
	test "$$result" -eq 12; \
	grep -q 'Invariant StableAtEnd is violated' "$(BUILD_DIR)/selection-witness.log"

heap-witness:
	test -f "$(TLA_TOOLS_JAR)"
	mkdir -p "$(BUILD_DIR)"
	cd heap_sort; set +e; \
	java $(JAVA_FLAGS) -cp "$(TLA_TOOLS_JAR)" tlc2.TLC -workers 1 -noGenerateSpecTE \
	    -metadir "$(BUILD_DIR)/heap-witness-states" -config Unstable.cfg HeapSort.tla \
	    > "$(BUILD_DIR)/heap-witness.log" 2>&1; result=$$?; set -e; \
	cat "$(BUILD_DIR)/heap-witness.log"; \
	test "$$result" -eq 12; \
	grep -q 'Invariant StableAtEnd is violated' "$(BUILD_DIR)/heap-witness.log"
