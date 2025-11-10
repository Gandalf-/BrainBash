# BrainBash Test Suite

This directory contains automated tests for the BrainBash Brainfuck interpreter.

## Test Framework

Tests are written using [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core), a TAP-compliant testing framework for Bash.

## Test Structure

```
tests/
├── unit/                       # Unit tests for individual operations
│   ├── basic_operations.bats  # Tests for +, -, >, <, [, ], etc.
│   └── optimizations.bats     # Tests for optimization correctness
├── integration/                # Integration tests
│   └── example_programs.bats  # Tests for example .bf programs
├── helpers/                    # Test utilities
│   └── test_helper.bash       # Common test helper functions
├── bats/                       # BATS core framework (submodule)
└── test_helper/                # BATS helper libraries (submodules)
    ├── bats-support/           # BATS support library
    └── bats-assert/            # BATS assertion library
```

## Running Tests

### Using Make (recommended):
```bash
make test                  # Run all tests
make lint                  # Run shellcheck
make all                   # Run lint and tests
```

### Using BATS directly:
```bash
# Run all tests
tests/bats/bin/bats tests/unit/ tests/integration/

# Run specific test suite
tests/bats/bin/bats tests/unit/basic_operations.bats
tests/bats/bin/bats tests/unit/optimizations.bats
tests/bats/bin/bats tests/integration/example_programs.bats

# Run a single test
tests/bats/bin/bats tests/unit/basic_operations.bats --filter "increment"
```

### Requirements:
- BATS (included as git submodule)
- shellcheck (for linting): `apt-get install shellcheck`

## Test Coverage

### Unit Tests (55 tests)

**basic_operations.bats** (15 tests) - Core Brainfuck operations:
- Increment/decrement operations (+/-)
- Tape movement (>/<)
- Loops ([/])
- Output operations (.)
- Edge cases (underflow, empty programs, comments)
- Non-brainfuck character handling

**optimizations.bats** (28 tests) - Optimization correctness:
- Simple optimizations (repeated operations)
- Heavy optimizations (move patterns, zeroing, copies)
- Equivalence testing (optimized vs non-optimized output)
- Pattern recognition (moves, copies, zeroing)

**cli_options.bats** (10 tests) - Command-line options:
- Help and usage display
- Optimization flags (-o, -O)
- Print and profile flags (-p, -P)
- Max iterations (-i)
- Quiet mode (-q)
- Compile mode (-c)

**edge_cases.bats** (12 tests) - Edge case handling:
- Large tape values
- Extended tape movement
- Empty loops
- Wraparound behavior
- Rapid tape movement
- Long operation sequences

### Integration Tests (9 tests)

**example_programs.bats** - Example programs:
- hello_world.bf, alphabet.bf
- simple.bf, loop.bf, nested_loop.bf
- optimize.bf, multiply.bf, copy.bf, counter.bf

## Adding New Tests

1. Create a new .bats file in the appropriate directory (unit/ or integration/)
2. Load the test helper: `load '../helpers/test_helper'`
3. Write tests using the `@test` directive
4. Run tests locally before committing

### Example Test

```bash
@test "my new test" {
  run bash "$TM_SH" -q <(echo "+++")
  assert_success
  assert_output --partial "tape  : 3"
}
```

## Test Statistics

- **Total Tests**: 64
- **Unit Tests**: 55
  - Basic Operations: 15
  - Optimizations: 28
  - CLI Options: 10
  - Edge Cases: 12
- **Integration Tests**: 9
- **Test Execution Time**: ~10-15 seconds
