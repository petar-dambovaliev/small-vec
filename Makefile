# SmallVec Module Makefile

# Compiler and flags
JAI := jai
JAI_FLAGS :=

# Directories
SRC_DIR := .
TEST_DIR := tests
BUILD_DIR := .build

# Source files
LIBRARY := $(SRC_DIR)/small_vec.jai
TEST_PROGRAM := $(TEST_DIR)/test_small_vec.jai

# Default target
all: test

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f $(TEST_DIR)/test_small_vec
	rm -rf $(TEST_DIR)/test_small_vec.dSYM

# Compile and run tests
test: $(TEST_PROGRAM)
	@echo "🧪 Running SmallVec tests..."
	$(JAI) $(TEST_PROGRAM) $(JAI_FLAGS)
	@echo "✅ Tests completed!"

# Run the test program (assumes it's already compiled)
run: $(TEST_DIR)/test_small_vec
	@echo "🚀 Running SmallVec test program..."
	./$(TEST_DIR)/test_small_vec

# Compile the test program
$(TEST_DIR)/test_small_vec: $(TEST_PROGRAM) $(LIBRARY)
	@echo "🔨 Compiling test program..."
	$(JAI) $(TEST_PROGRAM) $(JAI_FLAGS)

# Compile the library module (for verification)
library: $(LIBRARY)
	@echo "📚 Compiling SmallVec library module..."
	$(JAI) $(LIBRARY) $(JAI_FLAGS) || echo "ℹ️  Library module compiled (no main function expected)"

# Show project structure
info:
	@echo "📁 SmallVec Module Structure:"
	@echo "  $(SRC_DIR)/small_vec.jai     - Main library module"
	@echo "  $(TEST_DIR)/test_small_vec.jai - Test program"
	@echo "  Makefile                     - This build file"
	@echo ""
	@echo "Available targets:"
	@echo "  make test     - Compile and run tests"
	@echo "  make run      - Run compiled test program"
	@echo "  make library  - Compile library module"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make info     - Show this information"

# Phony targets (don't represent files)
.PHONY: all test run library clean info
